import Foundation
@preconcurrency import JavaScriptKit
import Shared

struct ClientAPI: Sendable {
  enum Error: Swift.Error {
    case fetchError(Int)
    case unknown
  }

  var folderListing: @Sendable (_ path: String) async throws -> FolderListingResponse
  var fetchFile: @Sendable (_ path: String, _ etag: String?) async throws -> (data: Data, etag: String)?
  var fetchJson: @Sendable (_ path: String, _ etag: String?) async throws -> (json: JSValue, etag: String)?

  var putFile: @Sendable (_ data: Data, _ path: String) async throws -> String
  var delete: @Sendable (_ path: String) async throws -> Void
}
extension ClientAPI {
  func fetch(path: String, ifNotMatching etag: String? = nil) async throws -> (data: Data, etag: String)? {
    try await fetchFile(path, etag)
  }
  func fetch<T: Decodable>(path: String, ifNotMatching etag: String? = nil) async throws -> (object: T, etag: String)? {
    guard let (json, etag) = try await fetchJson(path, etag) else {
      return nil
    }
    return (try JSValueDecoder().decode(T.self, from: json), etag)
  }
  @discardableResult
  func put(file: Data, at path: String) async throws -> String {
    try await putFile(file, path)
  }
  @discardableResult
  func put(object: any Encodable, at path: String) async throws -> String {
    let data = try JSONEncoder().encode(object)
    return try await putFile(data, path)
  }
  func delete(file: String) async throws {
    try await delete(file)
  }
}

extension ClientAPI {
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

  static let live = Self(
    folderListing: { path in
      guard let (json, _) = try await fetchJson(url: baseUrl + path, etag: nil) else {
        throw Error.unknown
      }
      return try JSValueDecoder().decode(FolderListingResponse.self, from: json)
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
}

private protocol ConvertibleToJSObject {
  func jsObject() -> JSObject
}
extension Dictionary: ConvertibleToJSObject where Key == String {
  func jsObject() -> JSObject {
    let result = JSObject()
    for (key, value) in self {
      switch value {
      case let value as String:
        result[key] = JSValue(stringLiteral: value)
      case let value as Int32:
        result[key] = JSValue(integerLiteral: value)
      case let value as Double:
        result[key] = JSValue(floatLiteral: value)
      case let value as ConvertibleToJSObject:
        result[key] = value.jsObject().jsValue
      case let value as JSValue:
        result[key] = value
      default:
        print(key, value)
        fatalError()
      }
    }
    return result
  }
}