//
// Copyright © 2025 peter bohac. All rights reserved.
//

import AppShared
import Foundation
import JavaScriptEventLoop
@preconcurrency import JavaScriptKit
import SwiftNavigation

/// An observable model object for the main app UI.
@MainActor
@Perceptible
public final class MainViewModel {
  /// The path of the folder currently being displayed.
  public var path: [String] = [] {
    didSet {
      fetchCurrentDirectory()
    }
  }
  /// Timestamp of the last successful folder listing API call.
  public private(set) var lastFetchTimestamp: Date?
  /// The subfolders in the current directory.
  public private(set) var folders: [String] = []
  /// The files in the current directory.
  public private(set) var files: [String] = []

  /// The full path string of the current folder.
  public var pathString: String {
    "/" + path.joined(separator: "/")
  }

  /// The client API instance to use.
  private let clientApi = ClientAPI.live

  public init() {}

  /// Requests the current directory listing from the server.
  public func fetchCurrentDirectory() {
    Task {
      do {
        try await fetchCurrentDirectory()
      } catch {
        DOM.alert(error.message)
      }
    }
  }

  /// Deletes the item in the current directory and then refreshes the listing.
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

  /// Creates a new subfolder in the current directory and then refreshes the listing.
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

  /// Downloads a file from the current directory.
  public func download(file: String) {
    Task {
      do {
        guard let response = try await clientApi.fetch(path: fullPath(for: file))?.response,
          let obj = response.blob().object,
          let blob = try await JSPromise(obj)?.value
        else {
          throw UnexpectedError()
        }
        let href = Global.createObjectURL(blob)
        // Create a new link element and "click" it to cause the browser to prompt the user to save the file locally.
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

  /// Uploads a local file (selected by the user using the browser picker) to the server and refreshes the directory listing.
  public func upload(_ file: JSObject) {
    guard let name = file.name.string else {
      DOM.alert("Unable to determine the file's name")
      return
    }
    let path = fullPath(for: name)
    let fileReader = Global.FileReader.new().jsValue
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

  /// Gets the full path for an item in the current directory.
  private func fullPath(for item: String) -> String {
    pathString + "/" + item
  }

  private func fetchCurrentDirectory() async throws {
    let response = try await clientApi.folderListing(pathString)
    folders = response.directories
    files = response.files
    lastFetchTimestamp = .now.addingTimeInterval(Global.tzOffset * 60)
  }

  struct UnexpectedError: Swift.Error {}
}
