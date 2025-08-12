import AppShared
import JavaScriptEventLoop
import JavaScriptKit
import SwiftNavigation

@MainActor
@main
struct App {
  static private(set) var doc: JSValue!
  static private(set) var f7app: JSValue!
  static private(set) var dom7: JSFunction!

  static private var pages: [String: (page: Page, tokens: Set<ObserveToken>)] = [:]

  static func main() {
    JavaScriptEventLoop.installGlobalExecutor()
    print("Running…")
    setup()
    navigate(to: MainView())
  }

  static func setup() {
    doc = JSObject.global.document
    dom7 = JSObject.global.Dom7.function
    f7app = JSObject.global.app

    let loadingPage = doc.getElementById("loadingPage")
    _ = f7app.views.main.el.insertBefore(NavBar(title: "Fancy App").render(), loadingPage)

    _ = dom7(doc).on(
      "page:beforein",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        print("page:beforein", name)
        // _ = JSObject.global.console.log(f7page)
        guard var (page, tokens) = pages[name] else {
          return .undefined
        }
        tokens = [observe { page.observing() }]
        tokens.formUnion(page.observables())
        pages[name] = (page, tokens)
        page.onAdded()
        return .undefined
      }
    )
    _ = dom7(doc).on(
      "page:afterout",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        print("page:afterout", name)
        guard var (page, tokens) = pages[name] else {
          return .undefined
        }
        page.onRemoved()
        tokens.removeAll()
        pages[name] = (page, tokens)
        return .undefined
      }
    )
    _ = dom7(doc).on(
      "page:beforeremove",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        print("page:beforeremove", name)
        pages[name] = nil
        return .undefined
      }
    )
  }

  static func navigate(to page: Page) {
    pages[page.name] = (page, [])
    _ = f7app.views.main.router.navigate(
      [
        "url": "/swift/\(page.name)",
        "route": ["el": page.render()],
      ].jsObject()
    )
  }
}