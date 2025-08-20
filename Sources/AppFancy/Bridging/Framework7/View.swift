import JavaScriptKit
import SwiftNavigation

@MainActor
final class View {
  static let main = View(App.f7app.views.main)

  let node: JSValue

  private static var pages: [String: (page: Page, tokens: Set<ObserveToken>)] = [:]
  private var navbar: NavBar?

  private init(_ node: JSValue) {
    self.node = node
  }

  static func setup() {
    _ = App.dom7(App.doc).on(
      "page:beforein",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        guard let entry = pages[name] else {
          return .undefined
        }
        let page = entry.page
        var tokens = entry.tokens
        tokens = [observe { page.observing() }]
        tokens.formUnion(page.observables())
        pages[name] = (page, tokens)
        page.willBeAdded()
        return .undefined
      }
    )
    _ = App.dom7(App.doc).on(
      "page:afterin",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        pages[name]?.page.onAdded()
        return .undefined
      }
    )
    _ = App.dom7(App.doc).on(
      "page:beforeout",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        pages[name]?.page.willBeRemoved()
        return .undefined
      }
    )
    _ = App.dom7(App.doc).on(
      "page:afterout",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        guard let entry = pages[name] else {
          return .undefined
        }
        let page = entry.page
        var tokens = entry.tokens
        page.onRemoved()
        tokens.removeAll()
        pages[name] = (page, tokens)
        return .undefined
      }
    )
    _ = App.dom7(App.doc).on(
      "page:beforeremove",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        pages[name] = nil
        return .undefined
      }
    )
  }

  func insert(element: Element, before id: String) {
    let sibling = App.doc.getElementById(id)
    _ = node.el.insertBefore(element.render(parentNode: node.el), sibling)
    if let navbar = element as? NavBar {
      self.navbar = navbar
    }
  }

  func navigate(to destination: Page, transition: Transition? = nil) {
    let options: JSObject
    if let transition {
      options = ["transition": transition.rawValue].jsObject()
    } else {
      options = [:].jsObject()
    }
    let page = destination
      .environment(NavBar.self, navbar?.instance)
      .environment(View.self, self)
    Self.pages[page.name] = (page, [])
    _ = node.router.navigate(
      [
        "url": "/swift/\(page.name)",
        "route": ["el": page.render(parentNode: node.el)],
      ].jsObject(),
      options
    )
  }
}

extension View: EnvironmentKey {
  static let defaultValue: View? = nil
}

extension View {
  enum Transition: String {
    case circle = "f7-circle"
    case cover = "f7-cover"
    case verticalCover = "f7-cover-v"
    case dive = "f7-dive"
    case fade = "f7-fade"
    case flip = "f7-flip"
    case parallax = "f7-parallax"
    case push = "f7-push"
  }
}