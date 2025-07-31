@preconcurrency import JavaScriptKit

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
    addElement(view.body, to: parent, replace: replace)
    view.onAdded()
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
}

@MainActor
public protocol View {
  var body: JSValue { get }
  func onAdded()
}
public extension View {
  func onAdded() {}
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

  func on(_ event: String, _ handler: @escaping () -> Void) {
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