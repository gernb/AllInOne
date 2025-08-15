import AppShared
import JavaScriptKit

final class MainView: Page {
  let name = "main-view"
  private let model = MainViewModel()

  private var bottomToast: JSValue?

  var content: [Element] {
    PullToRefresh { [weak self] in
      try? await self?.model.fetchCurrentDirectory()
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

  func observing() {
    if let timestamp = model.lastFetchTimestamp {
      let value = timestamp.formatted(date: .abbreviated, time: .standard)
      _ = bottomToast?.close()
      bottomToast = App.showToast(text: "Last updated: \(value)")
    }
  }

  func willBeAdded() {
    NavBar.showBackButton(false)
    model.fetchCurrentDirectory()
  }

  func willBeRemoved() {
    _ = bottomToast?.close()
    bottomToast = nil
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