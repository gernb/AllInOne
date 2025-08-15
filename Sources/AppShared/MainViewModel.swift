import Foundation
import JavaScriptEventLoop
@preconcurrency import JavaScriptKit
import SwiftNavigation

@MainActor
@Perceptible
public final class MainViewModel {
  public var path: [String] = [] {
    didSet {
      fetchCurrentDirectory()
    }
  }
  public private(set) var lastFetchTimestamp: Date?
  public private(set) var folders: [String] = []
  public private(set) var files: [String] = []

  public var pathString: String {
    "/" + path.joined(separator: "/")
  }

  private let clientApi = ClientAPI.live

  public init() {}

  public func fetchCurrentDirectory() {
    Task {
      do {
        try await fetchCurrentDirectory()
      } catch {
        DOM.alert(error.message)
      }
    }
  }

  public func fetchCurrentDirectory() async throws {
    let response = try await clientApi.folderListing(pathString)
    folders = response.directories
    files = response.files
    lastFetchTimestamp = .now.addingTimeInterval(DOM.tzOffset * 60)
  }

  public func delete(_ item: String) {
    Task {
      do {
        try await clientApi.delete(path: fullPath(for: item))
        try await fetchCurrentDirectory()
      } catch {
        DOM.alert(error.message)
      }
    }
  }

  public func createFolder(_ name: String) {
    Task {
      do {
        try await clientApi.createFolder(at: fullPath(for: name))
        try await fetchCurrentDirectory()
      } catch {
        DOM.alert(error.message)
      }
    }
  }

  public func download(file: String) {
    Task {
      do {
        guard let response = try await clientApi.fetch(path: fullPath(for: file))?.response,
          let obj = response.blob().object,
          let blob = try await JSPromise(obj)?.value
        else {
          throw UnexpectedError()
        }
        let href = DOM.createObjectURL(blob)
        let link = DOM.create("a") {
          $0.href = href
          $0.download = .string(file)
        }
        _ = link.click()
      } catch {
        DOM.alert(error.message)
      }
    }
  }

  public func upload(_ file: JSObject) {
    guard let name = file.name.string else {
      DOM.alert("Unable to determine the file's name")
      return
    }
    let path = fullPath(for: name)
    let fileReader = JSObject.global.FileReader.function!.new().jsValue
    fileReader.event("load") { [weak self] in
      let bytesArray = JSObject.global.Uint8Array.function!.new(fileReader.result)
      let fileData = JSTypedArray<UInt8>(unsafelyWrapping: bytesArray).withUnsafeBytes(
        Data.init(buffer:))
      Task {
        guard let self else { return }
        do {
          try await self.clientApi.put(file: fileData, at: path)
          try await self.fetchCurrentDirectory()
        } catch {
          DOM.alert(error.message)
        }
      }
    }
    fileReader.event("error") {
      DOM.alert("Something went wrong")
    }
    _ = fileReader.readAsArrayBuffer(file)
  }

  private func fullPath(for item: String) -> String {
    pathString + "/" + item
  }

  struct UnexpectedError: Swift.Error {}
}
