import Foundation
import JavaScriptKit
import SwiftNavigation

@MainActor
final class View {
  static var current: View? { Environment[View.self] }
  static let main = View(App.f7app.views.main)

  let node: JSValue

  private static let views: [String: View] = [
    View.main.node.name.string!: .main,
  ]
  private static var pages: [String: (page: Page, tokens: Set<ObserveToken>)] = [:]

  private var pageRegistry: [String: Page] = [:]
  private var navbar: NavBar?

  private init(_ node: JSValue) {
    self.node = node
  }

  static func setup() {
    let routes = [
      [
        "name": "swift",
        "path": "/swift/:id",
        "async": JSClosure { args in
          let context = args[0]
          let id = context.to.params.id.string!
          let viewName = context.router.view.name.string!
          let view = Self.views[viewName]!
          let page = view.pageRegistry[id]!
          let resolve = context.resolve.function!
          _ = resolve([
            "el": page.render(parentNode: View.main.node)
          ])
          return .undefined
        }
      ].jsObject()
    ]
    View.main.node.router.routes = routes.jsValue
    View.main.node.history.length = 0

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

        if let wrapped = page as? EnvironmentWrapper {
          wrapped.withEnvironment {
            guard let navbar = NavBar.current else { return }
            let historyLen = f7page.view.history.length.number!
            if historyLen <= 1 {
              navbar.showBackButton(false)
            } else {
              navbar.showBackButton(true)
            }
          }
        }

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
    // _ = App.dom7(App.doc).on(
    //   "page:beforeremove",
    //   JSClosure { args in
    //     let f7page = args[1].object!
    //     let name = f7page.name.string!
    //     pages[name] = nil
    //     return .undefined
    //   }
    // )
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
    let id = UUID().uuidString
    pageRegistry[id] = page
    _ = node.router.navigate(
      [
        "name": "swift",
        "params": [ "id": id ],
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