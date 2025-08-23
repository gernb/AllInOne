//
// Copyright © 2025 peter bohac. All rights reserved.
//

import Foundation
import JavaScriptEventLoop
@preconcurrency import JavaScriptKit
import Shared

/// A protocol witness for the client interface to the server API.
public struct ClientAPI: Sendable {
  enum Error: Swift.Error {
    /// An error that occurs when attempting to fetch data from the server.
    case fetchError(Int)
    /// A catch-all for all other unspecified errors.
    case unknown
  }

  /// Requests the folder listing (contents) from the server for the provided path.
  /// - Parameter path: The full path (relative to the root of the file server) to get the folder listing for.
  /// - Returns: The `FolderListingResponse` from the server.
  public var folderListing: @Sendable (_ path: String) async throws -> FolderListingResponse

  /// Fetch (download) the file at the given path as a `JSValue`.
  /// If the client already has a local copy it can provide the ETag of the local copy
  /// and the server can respond with status 304 instead of the file contents.
  var fetch: @Sendable (_ path: String, _ etag: String?) async throws -> (response: JSValue, etag: String)?
  /// Fetch (download) the file at the given path as `Data`.
  /// If the client already has a local copy it can provide the ETag of the local copy
  /// and the server can respond with status 304 instead of the file contents.
  var fetchFile: @Sendable (_ path: String, _ etag: String?) async throws -> (data: Data, etag: String)?
  /// Fetch (download) the file at the given path as `JSON`.
  /// If the client already has a local copy it can provide the ETag of the local copy
  /// and the server can respond with status 304 instead of the file contents.
  var fetchJson: @Sendable (_ path: String, _ etag: String?) async throws -> (json: JSValue, etag: String)?

  /// Upload a local file (as `Data`) to the given path on the server.
  /// - Returns: The ETag of the newly uploaded file contents.
  var putFile: @Sendable (_ data: Data, _ path: String) async throws -> String
  /// Create a new empty folder on the server at the given path.
  /// - Returns: The ETag of the newly created folder on the server.
  var createFolder: @Sendable (_ path: String) async throws -> String
  /// Delete the file or folder on the server at the given path.
  var delete: @Sendable (_ path: String) async throws -> Void
}

public extension ClientAPI {
  /// Download the file at the given path as a `JSValue`.
  /// If the client already has a local copy it can provide the ETag of the local copy
  /// and the server can respond with status 304 instead of the file contents.
  /// - Parameters:
  ///   - path: The full path of the file to download.
  ///   - etag: (optional) The ETag of the local copy of the file.
  /// - Returns: The file as a `JSValue` and the ETag of the file contents, or `nil` if the client ETag matches the server's ETag.
  func fetch(path: String, ifNotMatching etag: String? = nil) async throws -> (response: JSValue, etag: String)? {
    try await fetch(path, etag)
  }
  /// Download the file at the given path as `Data`.
  /// If the client already has a local copy it can provide the ETag of the local copy
  /// and the server can respond with status 304 instead of the file contents.
  /// - Parameters:
  ///   - path: The full path of the file to download.
  ///   - etag: (optional) The ETag of the local copy of the file.
  /// - Returns: The file as `Data` and the ETag of the file contents, or `nil` if the client ETag matches the server's ETag.
  func fetch(path: String, ifNotMatching etag: String? = nil) async throws -> (data: Data, etag: String)? {
    try await fetchFile(path, etag)
  }
  /// Download the file at the given path as JSON and attempt to decode it.
  /// If the client already has a local copy it can provide the ETag of the local copy
  /// and the server can respond with status 304 instead of the file contents.
  /// - Parameters:
  ///   - path: The full path of the object to download.
  ///   - etag: (optional) The ETag of the local copy of the file.
  /// - Returns: The file decoded as the provided object type and the ETag of the file contents, or `nil` if the client ETag matches the server's ETag.
  func fetch<T: Decodable>(path: String, ifNotMatching etag: String? = nil) async throws -> (object: T, etag: String)? {
    guard let (json, etag) = try await fetchJson(path, etag) else {
      return nil
    }
    return (try JSValueDecoder().decode(T.self, from: json), etag)
  }
  /// Upload a file to the given path.
  /// - Parameters:
  ///   - file: The file `Data`.
  ///   - path: The destination path on the server.
  /// - Returns: The server ETag for the newly uploaded file.
  @discardableResult
  func put(file: Data, at path: String) async throws -> String {
    try await putFile(file, path)
  }
  /// Upload an object as JSON to the given path.
  /// - Parameters:
  ///   - object: The object to encode as JSON and upload.
  ///   - path: The destination path on the server.
  /// - Returns: The server ETag for the newly uploaded file.
  @discardableResult
  func put(object: any Encodable, at path: String) async throws -> String {
    let data = try JSONEncoder().encode(object)
    return try await putFile(data, path)
  }
  /// Create a new empty folder on the server at the given path.
  /// - Parameter path: The full path on the server for the new folder.
  /// - Returns: The server ETag for the newly created folder.
  @discardableResult
  func createFolder(at path: String) async throws -> String {
    try await createFolder(path)
  }
  /// Delete the file or folder at the given path.
  /// - Parameter path: The full path of the file or folder to delete.
  func delete(path: String) async throws {
    try await delete(path)
  }
}

/// An implementation of the protocol that talks to a live server.
public extension ClientAPI {
  static let live = Self(
    folderListing: { path in
      guard let (json, _) = try await fetchJson(url: baseUrl + path, etag: nil) else {
        throw Error.unknown
      }
      return try JSValueDecoder().decode(FolderListingResponse.self, from: json)
    },
    fetch: { path, currentEtag in
      try await jsFetch(baseUrl + path, etag: currentEtag)
    },
    fetchFile: { path, currentEtag in
      guard let (resp, etag) = try await jsFetch(baseUrl + path, etag: currentEtag) else {
        return nil
      }
      guard let obj = resp.arrayBuffer().object, let buffer = try await JSPromise(obj)?.value else {
        throw Error.unknown
      }
      let bytesArray = JSObject.global.Uint8Array.function!.new(buffer)
      return (
        JSTypedArray<UInt8>(unsafelyWrapping: bytesArray).withUnsafeBytes(Data.init(buffer:)),
        etag
      )
    },
    fetchJson: { path, currentEtag in
      try await fetchJson(url: baseUrl + path, etag: currentEtag)
    },
    putFile: { data, path in
      let jsFetch = JSObject.global.fetch.function!
      let options = [
        "method": "POST",
        "headers": ["Content-Type": "application/octet-stream"],
        "body": JSTypedArray<UInt8>(data).jsValue,
      ].jsObject()
      let resp = try await JSPromise(jsFetch(baseUrl + path, options).object!)!.value
      let response = resp.object!
      guard response.ok.boolean == true else {
        let status = Int(response.status.number ?? 0)
        throw Error.fetchError(status)
      }
      guard let obj = resp.json().object, let json = try await JSPromise(obj)?.value else {
        throw Error.unknown
      }
      let result = try JSValueDecoder().decode(UploadResponse.self, from: json)
      return result.etag
    },
    createFolder: { path in
      let jsFetch = JSObject.global.fetch.function!
      let options = [
        "method": "POST",
      ].jsObject()
      let resp = try await JSPromise(jsFetch(baseUrl + path + "?isDirectory", options).object!)!.value
      let response = resp.object!
      guard response.ok.boolean == true else {
        let status = Int(response.status.number ?? 0)
        throw Error.fetchError(status)
      }
      guard let obj = resp.json().object, let json = try await JSPromise(obj)?.value else {
        throw Error.unknown
      }
      let result = try JSValueDecoder().decode(UploadResponse.self, from: json)
      return result.etag
    },
    delete: { path in
      let jsFetch = JSObject.global.fetch.function!
      let options = ["method": "DELETE"].jsObject()
      let resp = try await JSPromise(jsFetch(baseUrl + path, options).object!)!.value
      let response = resp.object!
      guard response.ok.boolean == true else {
        let status = Int(response.status.number ?? 0)
        throw Error.fetchError(status)
      }
    }
  )

  // This needs to match the router group configured on the server.
  private static let baseUrl = "/api/v1/files"
  private static func jsFetch(_ url: String, etag: String? = nil) async throws -> (response: JSValue, etag: String)? {
    let jsFetch = JSObject.global.fetch.function!
    let options = if let etag {
        ["headers": ["If-None-Match": etag]].jsObject()
      } else {
        JSObject()
      }
    let resp = try await JSPromise(jsFetch(url, options).object!)!.value
    let response = resp.object!
    if response.status == 304 {
      print("Content unchanged")
      return nil
    }
    guard response.ok.boolean == true else {
      let status = Int(response.status.number ?? 0)
      throw Error.fetchError(status)
    }
    let etag = response.headers.get("etag").string ?? ""
    return (resp, etag)
  }
  private static func fetchJson(url: String, etag currentEtag: String?) async throws -> (json: JSValue, etag: String)? {
    guard let (resp, etag) = try await jsFetch(url, etag: currentEtag) else {
      return nil
    }
    guard let obj = resp.json().object, let json = try await JSPromise(obj)?.value else {
      throw Error.unknown
    }
    return (json, etag)
  }
}