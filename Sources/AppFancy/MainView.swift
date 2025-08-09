import JavaScriptKit

struct MainView: Element {
  func render() -> JSObject {
    Page(name: "home") {
      NavBar(title: "Fancy App")
    } content: {
      Card {
        HTML(.p) {
          $0.innerText = "Main View"
        }
      }
    }
    .render()
  }
}