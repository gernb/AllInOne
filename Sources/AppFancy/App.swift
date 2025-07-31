import AppShared
import JavaScriptEventLoop

@MainActor
@main
struct App {
  static func main() {
    JavaScriptEventLoop.installGlobalExecutor()
    DOM.addNew("span", to: DOM.doc.body, replace: true) {
      $0.innerText = "Fancy!"
    }
  }
}