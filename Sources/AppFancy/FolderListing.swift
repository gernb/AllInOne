import AppShared
import Foundation
import JavaScriptKit
import SwiftNavigation

struct FolderListing: Page {
  let name: String
  private let model: FolderListingModel

  init(path: String = "/") {
    self.name = "FolderListing:\(path)"
    self.model = FolderListingModel(path: path)
  }

  var content: [Element] {
    PullToRefresh {
      try? await model.fetchCurrentDirectory()
    }

    HTML(.div) {
      $1.style.margin = "10px"
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
    Environment[NavBar.self]?.showBackButton(model.isRoot == false)
    Environment[NavBar.self]?.setToolbarItems {
      Popover {
        Icon(.lineHorizontal3)
      } content: {
        List {
          ActionListItem(title: "New Folder", icon: .folderBadgePlus, action: createFolder)
          ActionListItem(title: "Upload File", icon: .arrowUpDoc, action: uploadFile)
        }
        .listStyle(.itemDividers)
      }
    }
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

@Perceptible
@MainActor
final class FolderListingModel {
  let path: String
  var isRoot: Bool {
    path == "/"
  }
  var pathList: [String] {
    path.components(separatedBy: "/").filter { $0.isEmpty == false }
  }
  private(set) var lastFetchTimestamp: Date?
  private(set) var folders: [String] = []
  private(set) var files: [String] = []

  private let clientApi = ClientAPI.live

  init(path: String) {
    self.path = path
  }

  func fetchCurrentDirectory() async throws {
    let response = try await clientApi.folderListing(path)
    folders = response.directories
    files = response.files
    lastFetchTimestamp = .now.addingTimeInterval(Global.tzOffset * 60)
  }

  func path(for item: String) -> String {
    if path.hasSuffix("/") {
      path + item
    } else {
      path + "/" + item
    }
  }

  func delete(_ item: String) async throws {
    try await clientApi.delete(path: path(for: item))
    try await fetchCurrentDirectory()
  }

  func download(file: String) async throws {
    guard let response = try await clientApi.fetch(path: path(for: file))?.response,
      let obj = response.blob().object,
      let blob = try await JSPromise(obj)?.value
    else {
      struct DownloadFailure: Swift.Error {}
      throw DownloadFailure()
    }
    let link = HTML(.a) {
      $1.href = Global.createObjectURL(blob)
      $1.download = .string(file)
    }
    .render(parentNode: .undefined)
    .jsValue
    _ = link.click()
  }

  func createFolder(_ name: String) async throws {
    try await clientApi.createFolder(at: path(for: name))
    try await fetchCurrentDirectory()
  }

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