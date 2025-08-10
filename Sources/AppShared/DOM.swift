@preconcurrency import JavaScriptKit
import SwiftNavigation

@MainActor
public enum DOM {
  public static let doc = JSObject.global.document
  public static let window = JSObject.global.window
  public static let jsAlert = JSObject.global.alert.function!
  public static let createObjectURL = JSObject.global.URL.function!.createObjectURL!
  public static let Date = JSObject.global.Date.function!
  public static let tzOffset = -DOM.Date.new().jsValue.getTimezoneOffset().number!

  public static var locationPath: String {
    window.location.pathname.string ?? "/"
  }

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

  public static func create(_ element: String, builder: (JSValue) -> Void = { _ in }) -> JSValue {
    let node = doc.createElement(element)
    builder(node)
    return node
  }

  public static func addView(_ view: View, to parent: JSValue, replace: Bool = false) {
    let element = view.render()
    addElement(element, to: parent, replace: replace)
    observeView(view, node: element)
  }

  public static func addElement(_ element: JSValue, to parent: JSValue, replace: Bool = false) {
    if replace {
      _ = parent.replaceChildren(element)
    } else {
      _ = parent.appendChild(element)
    }
  }

  public static func alert(_ message: CustomStringConvertible) {
    _ = jsAlert(message.description)
  }

  private static func observeView(_ view: View, node: JSValue) {
    _ = rootObserver
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

  private static var views: [JSObject: (view: View, tokens: Set<ObserveToken>)] = [:]

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

@MainActor
public protocol View {
  func render() -> JSValue
  func observing()
  func observables() -> Set<ObserveToken>
  func onAdded()
  func onRemoved()
}
public extension View {
  func observing() {}
  func observables() -> Set<ObserveToken> { [] }
  func onAdded() {}
  func onRemoved() {}
}

public protocol ConvertibleToJSObject {
  func jsObject() -> JSObject
}
extension Dictionary: ConvertibleToJSObject where Key == String {
  public func jsObject() -> JSObject {
    let result = JSObject()
    for (key, value) in self {
      switch value {
      case let value as String:
        result[key] = JSValue(stringLiteral: value)
      case let value as Int32:
        result[key] = JSValue(integerLiteral: value)
      case let value as Double:
        result[key] = JSValue(floatLiteral: value)
      case let value as Bool:
        result[key] = .boolean(value)
      case let value as JSObject:
        result[key] = .object(value)
      case let value as ConvertibleToJSObject:
        result[key] = value.jsObject().jsValue
      case let value as JSValue:
        result[key] = value
      default:
        print(key, value)
        fatalError()
      }
    }
    return result
  }
}

public extension JSValue {
  func onClick(_ handler: @escaping () -> Void) {
      self.onclick = .object(
        JSClosure { _ in
          handler()
          return .undefined
        }
      )
  }

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

extension JSValue: @retroactive @unchecked Sendable {}
extension JSPromise: @retroactive @unchecked Sendable {}