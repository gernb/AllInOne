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
    NavBar.showBackButton(model.isRoot == false)
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
  @PerceptionIgnored
  private var toast: JSValue?

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

  func createFolder(_ name: String) async throws {
    try await clientApi.createFolder(at: path(for: name))
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
    let href = Global.createObjectURL(blob)
    let link = HTML(.a) {
      $1.href = href
      $1.download = .string(file)
    }
    .render(parentNode: .undefined)
    .jsValue
    _ = link.click()
  }
}