public struct FolderListingResponse: Codable, Sendable {
  public let status: Int
  public let files: [String]
  public let directories: [String]

  public init(status: Int, files: [String] = [], directories: [String] = []) {
    self.status = status
    self.files = files
    self.directories = directories
  }
}

public struct UploadResponse: Codable, Sendable {
  public let status: Int
  public let etag: String

  public init(status: Int, etag: String) {
    self.status = status
    self.etag = etag
  }
}
