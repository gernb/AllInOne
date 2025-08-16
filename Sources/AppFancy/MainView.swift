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
    Block(style: .inset) {
      Block(style: .outline) {
        let items: [String] = ["one", "two", "three"]
        Breadcrumbs(items)
      }
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
  }

  func observing() {
    if let timestamp = model.lastFetchTimestamp {
      let value = timestamp.formatted(date: .abbreviated, time: .standard)
      model.showToast(text: "Last updated: \(value)")
    } else {
      model.hideToast()
    }
  }

  func willBeAdded() {
    NavBar.showBackButton(model.isRoot == false)
    Task {
      try? await model.fetchCurrentDirectory()
    }
  }

  func willBeRemoved() {
    model.hideToast()
  }
}

@Perceptible
@MainActor
final class MainViewModel {
  let path: String
  var isRoot: Bool {
    path == "/"
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

  func showToast(text: String) {
    if toast == nil || toast?.params.text.string != text {
      _ = toast?.close()
      toast = App.showToast(text: text)
    } else {
      print("toast text is unchanged")
    }
  }

  func hideToast() {
    _ = toast?.close()
    toast = nil
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