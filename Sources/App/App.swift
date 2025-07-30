import AppShared
import JavaScriptEventLoop

@MainActor
@main
struct App {
  private static let mainView = MainView()

  static func main() {
    JavaScriptEventLoop.installGlobalExecutor()
    DOM.addView(mainView, to: DOM.doc.body, replace: true)
  }
}