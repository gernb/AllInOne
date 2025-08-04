import AppShared
import JavaScriptEventLoop
import JavaScriptKit

@MainActor
@main
struct App {
  static private(set) var f7app: JSValue!

  static func main() {
    JavaScriptEventLoop.installGlobalExecutor()
    f7app = JSObject.global.app
    let homePageNode = DOM.create("div") {
      $0.className = "page"
      $0[dynamicMember: "data-name"] = "home"
      DOM.addNew("div", to: $0) {
        $0.className = "navbar"
        DOM.addNew("div", to: $0) {
          $0.className = "navbar-bg"
        }
        DOM.addNew("div", to: $0) {
          $0.className = "navbar-inner"
          DOM.addNew("div", to: $0) {
            $0.className = "title"
            $0.innerText = "Fancy App"
          }
        }
      }
      DOM.addNew("div", to: $0) {
        $0.className = "page-content"
        $0.innerText = "Loaded"
      }
    }
    _ = f7app.views.main.router.navigate(
      [
        "url": "/swift/",
        "route": ["el": homePageNode],
      ].jsObject()
    )
  }
}