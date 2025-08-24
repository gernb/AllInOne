//
// Copyright © 2025 peter bohac. All rights reserved.
//

import AppShared
import Foundation
import JavaScriptKit
import SwiftNavigation

/// The primary application UI.
/// Each instance of this type represents a single folder;
/// new instances are created and pushed on and popped off the nav stack.
struct FolderListing: Page {
  /// A unique name for this page
  let name: String
  /// The observable view model
  private let model: FolderListingModel

  /// Creates a new instance referencing a specific folder path.
  /// - Parameter path: The path for this instance; default is the root folder.
  init(path: String = "/") {
    self.name = "FolderListing:\(path)"
    self.model = FolderListingModel(path: path)
  }

  var content: [Element] {
    PullToRefresh {
      try? await model.fetchCurrentDirectory()
    }

    HTML(.div) {
      $1.style.margin = "10px 0 10px 10px"
    } containing: {
      Breadcrumbs(
        [("/", .house)] + model.pathList.map { ($0, .folder) }
      )

      List(id: list)

      BlockFooter {
        HTML(.span, id: timestampLabel)
      }
    }
  }

  // These allow the instance in the DOM to be found and referenced by the observation code.
  private let list = IdentifiedNode()
  private let timestampLabel = IdentifiedNode()

  func observing() {
    if let timestamp = model.lastFetchTimestamp {
      let value = timestamp.formatted(date: .abbreviated, time: .standard)
      timestampLabel.innerText = .string("Last updated: \(value)")
    } else {
      timestampLabel.innerText = ""
    }

    list.clear()
    for folder in model.folders {
      let item = NavigationListItem(
        title: folder,
        icon: .folderFill,
        destination: FolderListing(path: model.path(for: folder))
      )
      .swipeActions {
        Swipeout.Action(title: "Delete", color: .red) {
          confirmDelete(item: folder)
        }
      }
      list.add(item)
    }
    for file in model.files {
      let item = ActionListItem(title: file, icon: .docTextFill) {
        Task {
          do {
            try await model.download(file: file)
          } catch {
            print(error.message)
            App.showAlert(text: error.message, title: "Something went wrong")
          }
        }
      }
      .swipeActions {
        Swipeout.Action(title: "Delete", color: .red) {
          confirmDelete(item: file)
        }
      }
      list.add(item)
    }
  }

  func willBeAdded() {
    // Each instance has the same UI, but uniquely references this instance's model.
    NavBar.current?.setToolbarItems {
      Popover {
        Icon(.lineHorizontal3)
      } content: {
        List {
          ActionListItem(title: "New Folder", icon: .folderBadgePlus, action: createFolder)
          ActionListItem(title: "Upload File", icon: .arrowUpDoc, action: uploadFile)
          if let debugModel = AppMain.debugConsoleModel {
            ActionListItem(title: "Show debug console", icon: .listBelowRectangle) {
              guard App.currentSheet == nil else { return }
              App.showSheet(
                DebugConsoleSheet(model: debugModel),
                detents: [0.33, 0.67]
              )
            }
          }
        }
        .listStyle(.itemDividers)
      }
    }

    // Load this instance's directory listing.
    Task {
      try? await model.fetchCurrentDirectory()
    }
  }

  private func confirmDelete(item: String) {
    App.showConfirmDialog(text: "Do you want to delete '\(item)'?") {
      Task {
        do {
          try await model.delete(item)
        } catch {
          print(error.message)
          App.showAlert(text: error.message, title: "Something went wrong")
        }
      }
    }
  }

  private func createFolder() {
    App.showPrompt(text: "Folder name:") {
      let folderName = $0.trimmingCharacters(in: .whitespaces)
      guard folderName.isEmpty == false else {
        return
      }
      Task {
        do {
          try await model.createFolder(folderName)
        } catch {
          print(error.message)
          App.showAlert(text: error.message, title: "Something went wrong")
        }
      }
    }
  }

  private func uploadFile() {
    let fileInput = HTML(.tag("input")) {
      $1.style.display = "none"
      $1.type = "file"
      _ = $1.addEventListener(
        "change",
        JSClosure { args in
          Task {
            do {
              try await model.upload(args[0].target.files)
            } catch {
              App.showAlert(text: error.message, title: "Something went wrong")
            }
          }
          return .undefined
        }
      )
    }
    .render(parentNode: .undefined)
    .jsValue
    _ = fileInput.click()
  }
}

/// An observable view model for this page.
@Perceptible
@MainActor
final class FolderListingModel {
  /// The full path for this folder.
  let path: String
  /// Each folder component (including the root folder) in this path.
  var pathList: [String] {
    path.components(separatedBy: "/").filter { $0.isEmpty == false }
  }
  /// The timestamp of the last successful folder listing update.
  private(set) var lastFetchTimestamp: Date?
  /// The subfolders in this directory.
  private(set) var folders: [String] = []
  /// The files in this directory.
  private(set) var files: [String] = []

  /// The client API instance to use.
  private let clientApi = ClientAPI.live

  init(path: String) {
    self.path = path
  }

  /// Updates the directory contents by fetching the listing from the server.
  func fetchCurrentDirectory() async throws {
    let response = try await clientApi.folderListing(path)
    folders = response.directories
    files = response.files
    lastFetchTimestamp = .now.addingTimeInterval(Global.tzOffset * 60)
  }

  /// The full path of an item (file or folder) in this directory.
  func path(for item: String) -> String {
    if path.hasSuffix("/") {
      path + item
    } else {
      path + "/" + item
    }
  }

  /// Deletes an item from this directory and refreshes the listing.
  func delete(_ item: String) async throws {
    try await clientApi.delete(path: path(for: item))
    try await fetchCurrentDirectory()
  }

  /// Downloads a file from this directory.
  func download(file: String) async throws {
    guard let response = try await clientApi.fetch(path: path(for: file))?.response,
      let obj = response.blob().object,
      let blob = try await JSPromise(obj)?.value
    else {
      struct DownloadFailure: Swift.Error {}
      throw DownloadFailure()
    }
    // Render a link and "click" it to cause the browser to present a file save dialog.
    let link = HTML(.a) {
      $1.href = Global.createObjectURL(blob)
      $1.download = .string(file)
    }
    .render(parentNode: .undefined)
    .jsValue
    _ = link.click()
  }

  /// Creates a new subfolder in this directory and refreshes the listing.
  func createFolder(_ name: String) async throws {
    try await clientApi.createFolder(at: path(for: name))
    try await fetchCurrentDirectory()
  }

  /// Uploads a file (selected by the user from a standard browser picker) to the directory and refreshes the listing.
  func upload(_ files: JSValue) async throws {
    struct UnknownError: Swift.Error {}
    guard files.length == 1, let file = files[0].object, let name = file.name.string else {
      throw UnknownError()
    }
    let path = path(for: name)
    try await withCheckedThrowingContinuation { continuation in
      let fileReader = Global.FileReader.new().jsValue
      _ = fileReader.addEventListener(
        "load",
        JSClosure { [weak self] _ in
          let bytesArray = JSObject.global.Uint8Array.function!.new(fileReader.result)
          let fileData = JSTypedArray<UInt8>(unsafelyWrapping: bytesArray).withUnsafeBytes(Data.init(buffer:))
          Task {
            guard let self else {
              continuation.resume()
              return
            }
            do {
              try await self.clientApi.put(file: fileData, at: path)
              try await self.fetchCurrentDirectory()
              continuation.resume()
            } catch {
              continuation.resume(throwing: error)
            }
          }
          return .undefined
        }
      )
      _ = fileReader.addEventListener(
        "error",
        JSClosure { _ in
          continuation.resume(throwing: UnknownError())
          return .undefined
        }
      )
      _ = fileReader.readAsArrayBuffer(file)
    }
  }
}