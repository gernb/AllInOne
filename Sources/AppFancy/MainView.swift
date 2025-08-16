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

      Block(style: .inset) {
        Card {
          HTML(.p) {
            $1.innerText = "Main View"
          }
          Button(label: "Page 2") {
            print("Click…")
            App.navigate(to: SecondView())
          }
          .frame(maxWidth: 150)
          .buttonStyle(fill: .solid, shape: .round)
        }
      }

      BlockFooter {
        HTML(.span, id: timestampLabel)
      }
    }
  }

  private let timestampLabel: IdentifiedNode = "timestampLabel"

  func observing() {
    if let timestamp = model.lastFetchTimestamp {
      let value = timestamp.formatted(date: .abbreviated, time: .standard)
      timestampLabel.innerText = .string("Last updated: \(value)")
    } else {
      timestampLabel.innerText = ""
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

struct SecondView: Page {
  let name = "second-view"

  var content: [Element] {
    HTML(.p) {
      $1.innerText = "page 2"
    }
  }

  func onAdded() {
    print("SecondView added")
    NavBar.showBackButton(true)
  }

  func onRemoved() {
    print("SecondView removed")
  }
}