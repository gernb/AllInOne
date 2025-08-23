//
// Copyright © 2025 peter bohac. All rights reserved.
//

@preconcurrency import JavaScriptKit
import SwiftNavigation

/// Swift bridging code for common browser DOM and JavaScript functionality.
@MainActor
public enum DOM {
  /// The root browser document object.
  public static let doc = JSObject.global.document
  /// The browser window object.
  public static let window = JSObject.global.window
  /// The JavaScript alert dialog function.
  public static let jsAlert = JSObject.global.alert.function!

  /// The path part of the window location URL.
  public static var locationPath: String {
    window.location.pathname.string ?? "/"
  }

  /// Add a new HTML element to an existing DOM element.
  /// - Parameters:
  ///   - element: The string name (tag) of the HTML element to create.
  ///   - parent: The DOM element this new element should be added to.
  ///   - replace: Whether to replace the children of the parent or add this element as a sibling; default is to add.
  ///   - builder: An optional function used to customise the new element.
  /// - Returns: The newly created DOM element.
  @discardableResult
  public static func addNew(
    _ element: String,
    to parent: JSValue,
    replace: Bool = false,
    builder: (JSValue) -> Void = { _ in }
  ) -> JSValue {
    let node = create(element, builder: builder)
    addElement(node, to: parent, replace: replace)
    return node
  }

  /// Creates a new HTML element, but does not add it to the DOM.
  /// - Parameters:
  ///   - element: The string name (tag) of the HTML element to create.
  ///   - builder: An optional function used to customise the new element.
  /// - Returns: The newly created element.
  public static func create(_ element: String, builder: (JSValue) -> Void = { _ in }) -> JSValue {
    let node = doc.createElement(element)
    builder(node)
    return node
  }

  /// Creates a new `View` and adds it toan existing DOM element.
  /// - Parameters:
  ///   - view: The `View` to render as HTML.
  ///   - parent: The DOM element this view should be added to.
  ///   - replace: Whether to replace the children of the parent or add this element as a sibling; default is to add.
  public static func addView(_ view: View, to parent: JSValue, replace: Bool = false) {
    let element = view.render()
    addElement(element, to: parent, replace: replace)
    observeView(view, node: element)
  }

  /// Adds the existing element to the DOM as a child of another existing DOM element.
  /// - Parameters:
  ///   - element: The element to add.
  ///   - parent: The DOM element this should be added to.
  ///   - replace: Whether to replace the children of the parent or add this element as a sibling; default is to add.
  public static func addElement(_ element: JSValue, to parent: JSValue, replace: Bool = false) {
    if replace {
      _ = parent.replaceChildren(element)
    } else {
      _ = parent.appendChild(element)
    }
  }

  /// Displays the provided input in a standard browser alert dialog.
  /// - Parameter message: The input to display.
  public static func alert(_ message: CustomStringConvertible) {
    _ = jsAlert(message.description)
  }

  /// Starts observing modifications when the element appears in the DOM
  /// and stops observing when the element is removed from the DOM.
  /// - Parameters:
  ///   - view: The `View` instance to observe.
  ///   - node: The rendered element for the instance being observed.
  private static func observeView(_ view: View, node: JSValue) {
    // Ensure the mutation observer is created and added.
    _ = rootObserver
    // Use a hidden "img" element to determine the moment when the view appears in the DOM.
    addNew("img", to: node) { img in
      img.width = 0
      img.height = 0
      img.src = ""
      img.loading = "lazy"
      img.event("error") {
        _ = img.remove()
        view.onAdded()
      }
    }
    var tokens: Set<ObserveToken> = [
      observe { view.observing() }
    ]
    tokens.formUnion(view.observables())
    views[node.object!] = (view, tokens)
  }

  // Keeps track of the rendered view elements and their corresponding `View` instances and observation tokens.
  private static var views: [JSObject: (view: View, tokens: Set<ObserveToken>)] = [:]

  // A lazy singleton that uses the JavaScript mutation observer to know when a tracked
  // `View` is removed from the DOM.
  private static let rootObserver: JSValue = {
    let observer = JSObject.global.MutationObserver.function!.new(
      JSClosure { _ in
        for (key, value) in views {
          let isConnected = key.isConnected.boolean ?? false
          if isConnected == false {
            value.view.onRemoved()
            views[key] = nil
          }
        }
        return .undefined
      }
    ).jsValue
    _ = observer.observe(doc.body, ["childList": true, "subtree": true].jsObject())
    return observer
  }()
}

/// A type that can render itself as HTML, can be observed for changes,
/// and provides callbacks when it is added to and removed from the DOM.
@MainActor
public protocol View {
  /// Generates the HTML, CSS, and JavaScript representation of this instance.
  func render() -> JSValue
  /// (optional) A single block of code that is observed for changes.
  func observing()
  /// (optional) A collection of observation tokens when more than block of code needs to be observed.
  func observables() -> Set<ObserveToken>
  /// (optional) Called when the instance appears in the DOM.
  func onAdded()
  /// (optional) Called when the instance is removed from the DOM.
  func onRemoved()
}
public extension View {
  func observing() {}
  func observables() -> Set<ObserveToken> { [] }
  func onAdded() {}
  func onRemoved() {}
}

public extension JSValue {
  /// Helper routine for adding a swift callback to the "click" event of an element.
  func onClick(_ handler: @escaping () -> Void) {
    self.onclick = .object(
      JSClosure { _ in
        handler()
        return .undefined
      }
    )
  }

  /// Helper routine that adds a swift callback to an arbitrary event of an element.
  /// - Parameters:
  ///   - event: The event to add a callback to.
  ///   - handler: The callback to invoke when the event occurs.
  func event(_ event: String, _ handler: @escaping () -> Void) {
    _ = self.addEventListener(
      event,
      JSClosure { _ in
        handler()
        return .undefined
      }
    )
  }
}