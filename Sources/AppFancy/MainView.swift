import AppShared
import Foundation
import JavaScriptKit
import SwiftNavigation

struct MainView: Page {
  let name = "main-view"
  private let model: MainViewModel

  init(path: String = "/") {
    self.model = MainViewModel(path: path)
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

      HTML(.ul, id: list)

      BlockFooter {
        HTML(.span, id: timestampLabel)
      }
    }
  }

  private let list: IdentifiedNode = "list"
  private let timestampLabel: IdentifiedNode = "timestampLabel"

  func observing() {
    if let timestamp = model.lastFetchTimestamp {
      let value = timestamp.formatted(date: .abbreviated, time: .standard)
      timestampLabel.innerText = .string("Last updated: \(value)")
    } else {
      timestampLabel.innerText = ""
    }

    _ = list.replaceChildren()
    for folder in model.folders {
      let item = HTML(.li) {
        Icon(.folderFill)
        HTML(.span) {
          $1.innerText = .string(folder)
        }
      }
      _ = list.appendChild(item.render(parentNode: list.node))
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
      let item = HTML(.li) {
        Icon(.docTextFill)
        HTML(.span) {
          $1.innerText = .string(file)
        }
      }
      _ = list.appendChild(item.render(parentNode: list.node))
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
    // _ = list.object.replaceChildren(listItems)
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
final class MainViewModel {
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
}