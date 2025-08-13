import JavaScriptKit

struct MainView: Page {
  let name = "main-view"

  var content: [Element] {
    Card {
      HTML(.p) {
        $0.innerText = "Main View"
      }
      Button(label: "Page 2") {
        print("Click…")
        App.navigate(to: SecondView())
      }
      .frame(maxWidth: 150)
      .buttonStyle(fill: .solid, shape: .round)
    }
  }

  func onAdded() {
    print("MainView added")
    NavBar.showBackButton(false)
  }

  func onRemoved() {
    print("MainView removed")
  }
}

struct SecondView: Page {
  let name = "second-view"

  var content: [Element] {
    HTML(.p) {
      $0.innerText = "page 2"
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