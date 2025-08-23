//
// Copyright © 2025 peter bohac. All rights reserved.
//

/// The shape of the data response returned by the server when asked for
/// the contents of a folder.
public struct FolderListingResponse: Codable, Sendable {
  public let status: Int
  public let files: [String]
  public let directories: [String]

  /// Creates a new folder listing response.
  /// - Parameters:
  ///   - status: The status code of the response. `0` means successful; anything else is an error.
  ///   - files: The collection of files (without the path prefix) in this folder.
  ///   - directories: The collection of subfolders (without the path prefix) in this folder.
  public init(status: Int, files: [String] = [], directories: [String] = []) {
    self.status = status
    self.files = files
    self.directories = directories
  }
}

/// The shape of the data response returned by the server when a file
/// has been uploaded.
public struct UploadResponse: Codable, Sendable {
  public let status: Int
  public let etag: String

  /// Creates a new upload response.
  /// - Parameters:
  ///   - status: The status code of the response. `0` means successful; anything else is an error.
  ///   - etag: The ETag for the newly uploaded file.
  public init(status: Int, etag: String) {
    self.status = status
    self.etag = etag
  }
}
