//
// Copyright © 2025 peter bohac. All rights reserved.
//

import Foundation
import JavaScriptKit
import SwiftNavigation

/// Wrapper that bridges the Framework7 View / Router widget to Swift.
/// Also implements the observation enhancements for the `Page` control.
/// https://framework7.io/docs/view
@MainActor
final class View {
  /// Gets the current View associated with the current element. May be `nil` if the element hasn't beed added to a view.
  static var current: View? { Environment[View.self] }

  /// The Framework7 "main" view that every app should have.
  static let main = View(App.f7app.views.main)

  /// The JavaScript node associated with this instance.
  let node: JSValue

  /// Tracks views by their name; allows for easy lookup of the instance by name.
  private static let views: [String: View] = [
    View.main.node.name.string!: .main,
  ]
  /// Tracks the page instance and observation tokens by the page name.
  private static var pages: [String: (page: Page, tokens: Set<ObserveToken>)] = [:]

  /// Tracks `Page` instances in the view by a unique ID. Used to map a route to the corresponding instance.
  private var pageRegistry: [String: Page] = [:]
  /// Tracks the optional NavBar instance installed in this view.
  private var navbar: NavBar?
  /// Tracks the optional Toolbar instance installed in this view.
  private var toolbar: Toolbar?

  private init(_ node: JSValue) {
    self.node = node
  }

  /// Must be called as early as possible in order to ensure routing and page observation works correctly.
  static func setup() {
    // Define an async route that maps a unique ID to a `Page` instance.
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
    // Clear any existing history (like a loading screen)
    View.main.node.history.length = 0

    // Setup an event listener to start observing a page right before it is added to the view.
    // Also controls whether the navbar back button should be visible.
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
    // Setup an event listener to invoke page life-cycle method after a page is added.
    _ = App.dom7(App.doc).on(
      "page:afterin",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        pages[name]?.page.onAdded()
        return .undefined
      }
    )
    // Setup an event listener to invoke page life-cycle method before page is removed.
    _ = App.dom7(App.doc).on(
      "page:beforeout",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        pages[name]?.page.willBeRemoved()
        return .undefined
      }
    )
    // Setup an event listener to invoke page life-cycle method after page is removed.
    // Also stops observing the page for changes.
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
    // The goal here was to keep the tracking dictionaries cleaned up, but this interferes with deep nav stacks...
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

  /// Add an element to the view before a sibling element.
  /// This is necessary for adding a common nav bar and/or toolbar.
  /// - Parameters:
  ///   - element: The element to add.
  ///   - id: The unique ID of the sibling element to add this before.
  func insert(element: Element, before id: String) {
    let sibling = App.doc.getElementById(id)
    _ = node.el.insertBefore(element.render(parentNode: node.el), sibling)
    if let navbar = element as? NavBar {
      self.navbar = navbar
    }
    if let toolbar = element as? Toolbar {
      self.toolbar = toolbar
    }
  }

  /// Push a new `Page` on to the nav stack and transition to it.
  /// - Parameters:
  ///   - destination: The `Page` to navigate to.
  ///   - transition: (optional) The transition to use; defaults to the platform (iOS or MD) appropriate transition for a forward navigation.
  func navigate(to destination: Page, transition: Transition? = nil) {
    let options: JSObject
    if let transition {
      options = ["transition": transition.rawValue].jsObject()
    } else {
      options = [:].jsObject()
    }
    let page = destination
      .environment(NavBar.self, navbar?.instance)
      .environment(Toolbar.self, toolbar?.instance)
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
  /// Navigation transitions supported by Framework7.
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