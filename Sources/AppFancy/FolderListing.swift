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
      let item = List.Item(
        title: folder,
        icon: .folderFill,
        trailingSwipeActions: [
          .init(title: "Delete") {
            print("Delete:", folder)
          }
        ]
      ) {
        let newPage = FolderListing(path: model.path(for: folder))
        App.navigate(to: newPage)
      }
      list.add(item)
      // let item = ListItem(folder, isFolder: true) {
      //   model.path.append(folder)
      // } trashTapped: {
      //   let confirmed = DOM.window.confirm("Do you want to delete '\(folder)'?").boolean!
      //   if confirmed {
      //     model.delete(folder)
      //   }
      // }
      // DOM.addView(item, to: list)
    }
    for file in model.files {
      let item = List.Item(title: file, icon: .docTextFill)
      list.add(item)
    //   let item = ListItem(file) {
    //     model.download(file: file)
    //   } trashTapped: {
    //     let confirmed = DOM.window.confirm("Do you want to delete '\(file)'?").boolean!
    //     if confirmed {
    //       model.delete(file)
    //     }
    //   }
    //   DOM.addView(item, to: list)
    }
  }

  func willBeAdded() {
    NavBar.showBackButton(model.isRoot == false)
    Task {
      try? await model.fetchCurrentDirectory()
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

  func path(for folder: String) -> String {
    if path.hasSuffix("/") {
      path + folder
    } else {
      path + "/" + folder
    }
  }
}