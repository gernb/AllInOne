//
// Copyright © 2025 peter bohac. All rights reserved.
//

import Foundation
import HTTPTypes
import Hummingbird
import MD5
import Shared

/// A file server middleware API that provides a REST interface for basic file CRUD operations.
struct FileController: Sendable {
  /// The root URL for all file operations
  let baseUrl: URL

  private let fileManager = FileManager.default
  private let fileIO = FileIO()
  private let encoder = JSONEncoder()

  /// Creates a new file controller instance.
  /// - Parameter dataPath: The root path (relative to the current working directory) for all file operations.
  init(dataPath: String) throws {
    let cwd = fileManager.currentDirectoryPath
    self.baseUrl = URL(filePath: cwd).appending(path: dataPath)
    if fileManager.fileExists(atPath: baseUrl.path(percentEncoded: false), isDirectory: nil) == false {
      try fileManager.createDirectory(at: baseUrl, withIntermediateDirectories: true)
    } else if try baseUrl.isDirectory() == false {
      struct ConfigError: Swift.Error {
        let message: String
      }
      throw ConfigError(message: "Unable to write files to '\(baseUrl.path(percentEncoded: false))'")
    }
  }

  /// Creates REST endpoints in the provided router group.
  /// - Parameter group: The router group to use as the base for the REST endpoints.
  func addRoutes(to group: RouterGroup<some RequestContext>) {
    group.get("/", use: self.download)
    group.get("**", use: self.download)
    group.post("**", use: self.upload)
    group.delete("**", use: self.delete)
  }

  @Sendable
  private func download(_ request: Request, context: some RequestContext) async throws -> Response {
    let path = try path(from: context)
    let url = baseUrl.appending(path: path)
    guard fileManager.fileExists(atPath: url.path(percentEncoded: false), isDirectory: nil) else {
      throw HTTPError(.notFound)
    }
    if try url.isDirectory() {
      let data = try encoder.encode(folderListing(for: url))
      return .init(
        status: .ok,
        headers: [.contentType: "application/json"],
        body: .init(byteBuffer: .init(bytes: data))
      )
    } else {
      if let clientEtag = request.headers[.ifNoneMatch], let serverEtag = try? etag(for: url) {
        if clientEtag.lowercased() == serverEtag.lowercased() {
          return .init(status: .notModified)
        }
      }
      let body = try await fileIO.loadFile(
        path: url.path(percentEncoded: false),
        context: context
      )
      return try .init(
        status: .ok,
        headers: headers(for: url),
        body: body
      )
    }
  }

  @Sendable
  private func upload(_ request: Request, context: some RequestContext) async throws -> UploadResponse {
   let path = try path(from: context)
   let url = baseUrl.appending(path: path)
    let isFolder = request.uri.queryParameters.has("isDirectory")
    if isFolder {
      context.logger.info("Creating directory: \(path)")
      try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    } else {
      let folder = url.deletingLastPathComponent()
      try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
      if fileManager.fileExists(atPath: url.path(percentEncoded: false)) {
        context.logger.info("Removing existing file: \(path)")
        try fileManager.removeItem(at: url)
      }
      context.logger.info("Writing file to: \(path)")
      try await fileIO.writeFile(
        contents: request.body,
        path: url.path(percentEncoded: false),
        context: context
      )
    }
    let etag = try self.etag(for: url)
    return .init(status: 0, etag: etag)
  }

  @Sendable
  private func delete(_ request: Request, context: some RequestContext) async throws -> Response {
    let path = try path(from: context)
    let url = baseUrl.appending(path: path)
    guard fileManager.fileExists(atPath: url.path(percentEncoded: false), isDirectory: nil) else {
      throw HTTPError(.notFound)
    }
    let isDirectory = try url.isDirectory()
    try fileManager.removeItem(at: url)
    if isDirectory {
      context.logger.info("Deleted folder: \(path)")
    } else {
      context.logger.info("Deleted file: \(path)")
    }
    return .init(status: .ok)
  }
}

/// Helper routines
extension FileController {
  /// Creates a response for the listing (contents) of a URL.
  /// - Parameter url: The full URL to get the listing of.
  /// - Returns: A new `FolderListingResponse`.
  private func folderListing(for url: URL) throws -> FolderListingResponse {
    var files: [String] = []
    var folders: [String] = []
    for item in try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey]) {
      let value = try item.resourceValues(forKeys: [.isDirectoryKey])
      if value.isDirectory == true {
        folders.append(item.lastPathComponent)
      } else {
        files.append(item.lastPathComponent)
      }
    }
    return FolderListingResponse(status: 0, files: files, directories: folders)
  }

  /// Gets the requested path from the input context.
  /// - Parameter context: The request input context.
  /// - Returns: The (relative) path from the request context.
  private func path(from context: some RequestContext) throws -> String {
      try "/" + context.parameters.getCatchAll()
        .map {
          guard let decoded = $0.removingPercentEncoding else {
            throw HTTPError(.badRequest)
          }
          return decoded
        }
        .joined(separator: "/")
  }

  /// Adds standard response headers for the given path URL.
  /// - Parameter url: The URL to use to generate the standard headers.
  /// - Returns: The standard reponse headers.
  private func headers(for url: URL) throws -> HTTPFields {
    return [
      .contentDisposition: "attachment;filename=\"\(url.lastPathComponent)\"",
      .eTag: try etag(for: url),
    ]
  }

  /// Generates the ETag for the given URL.
  /// - Parameter url: The URL to use to calculate the ETag.
  /// - Returns: The URL-specific ETag.
  private func etag(for url: URL) throws -> String {
    let attrs = try? fileManager.attributesOfItem(atPath: url.path(percentEncoded: false))
    let modDate = (attrs?[.modificationDate] as? Date) ?? .now
    let size = (attrs?[.size] as? Int) ?? 0
    let md5 = try MD5(hashing: encoder.encode(["modDate": Int(modDate.timeIntervalSince1970), "size": size]))
    return md5.description
  }
}

extension UploadResponse: ResponseEncodable {}

extension URL {
  /// Determines whether or not the URL is for a directory.
  /// - Returns: `true` if the URL is for a directory, `false` otherwise.
  func isDirectory() throws -> Bool {
    (try resourceValues(forKeys: [.isDirectoryKey])).isDirectory ?? false
  }
}

extension FileManager: @retroactive @unchecked Sendable {}