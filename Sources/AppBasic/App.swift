import AppShared
import JavaScriptEventLoop

@MainActor
@main
struct App {
  static func main() {
    JavaScriptEventLoop.installGlobalExecutor()
    DOM.addView(MainView(), to: DOM.doc.body, replace: true)
  }
}