import AppShared
import JavaScriptEventLoop
import JavaScriptKit

@MainActor
@main
struct App {
  static private(set) var f7app: JSValue!

  static func main() {
    JavaScriptEventLoop.installGlobalExecutor()
    print("Running…")
    f7app = JSObject.global.app
    let page = MainView()
    _ = f7app.views.main.router.navigate(
      [
        "url": "/swift/",
        "route": ["el": page.render()],
      ].jsObject()
    )
  }
}