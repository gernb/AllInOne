import Foundation
import HTTPTypes
import Hummingbird
import MD5
import Shared

struct FileController: Sendable {
  let baseUrl: URL

  private let fileManager = FileManager.default
  private let fileIO = FileIO()
  private let encoder = JSONEncoder()

  init(dataPath: String) throws {
    let cwd = fileManager.currentDirectoryPath
    self.baseUrl = URL(filePath: cwd).appending(path: dataPath)
    if fileManager.fileExists(atPath: baseUrl.path(), isDirectory: nil) == false {
      try fileManager.createDirectory(at: baseUrl, withIntermediateDirectories: true)
    } else if try baseUrl.isDirectory() == false {
      struct ConfigError: Swift.Error {
        let message: String
      }
      throw ConfigError(message: "Unable to write files to '\(baseUrl.path())'")
    }
  }

  func addRoutes(to group: RouterGroup<some RequestContext>) {
    group.get("/", use: self.download)
    group.get("**", use: self.download)
    group.post("**", use: self.upload)
    group.delete("**", use: self.delete)
  }

  @Sendable
  private func download(_ request: Request, context: some RequestContext) async throws -> Response {
    let path = "/" + context.parameters.getCatchAll().joined(separator: "/")
    let url = baseUrl.appending(path: path)
    guard fileManager.fileExists(atPath: url.path(), isDirectory: nil) else {
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
        path: url.path(),
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
    let path = "/" + context.parameters.getCatchAll().joined(separator: "/")
    let url = baseUrl.appending(path: path)
    let isFolder = request.uri.queryParameters.has("isDirectory")
    if isFolder {
      context.logger.info("Creating directory: \(path)")
      try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    } else {
      let folder = url.deletingLastPathComponent()
      try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
      if fileManager.fileExists(atPath: url.path()) {
        context.logger.info("Removing existing file: \(path)")
        try fileManager.removeItem(at: url)
      }
      context.logger.info("Writing file to: \(path)")
      try await fileIO.writeFile(
        contents: request.body,
        path: url.path(),
        context: context
      )
    }
    let etag = try self.etag(for: url)
    return .init(status: 0, etag: etag)
  }

  @Sendable
  private func delete(_ request: Request, context: some RequestContext) async throws -> Response {
    let path = "/" + context.parameters.getCatchAll().joined(separator: "/")
    let url = baseUrl.appending(path: path)
    guard fileManager.fileExists(atPath: url.path(), isDirectory: nil) else {
      throw HTTPError(.notFound)
    }
    try fileManager.removeItem(at: url)
    if try url.isDirectory() {
      context.logger.info("Deleted folder: \(path)")
    } else {
      context.logger.info("Deleted file: \(path)")
    }
    return .init(status: .ok)
  }
}

extension FileController {
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

  private func headers(for url: URL) throws -> HTTPFields {
    return [
      .contentDisposition: "attachment;filename=\"\(url.lastPathComponent)\"",
      .eTag: try etag(for: url),
    ]
  }

  private func etag(for url: URL) throws -> String {
    let attrs = try? fileManager.attributesOfItem(atPath: url.path())
    let modDate = (attrs?[.modificationDate] as? Date) ?? .now
    let size = (attrs?[.size] as? Int) ?? 0
    let md5 = try MD5(hashing: encoder.encode(["modDate": Int(modDate.timeIntervalSince1970), "size": size]))
    return md5.description
  }
}

extension UploadResponse: ResponseEncodable {}

extension URL {
  func isDirectory() throws -> Bool {
    (try resourceValues(forKeys: [.isDirectoryKey])).isDirectory ?? false
  }
}

extension FileManager: @retroactive @unchecked Sendable {}