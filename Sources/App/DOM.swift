@preconcurrency import JavaScriptKit

@MainActor
enum DOM {
  static let doc = JSObject.global.document
  static let window = JSObject.global.window
  static let jsAlert = JSObject.global.alert.function!

  @discardableResult
  static func addNew(
    _ element: String,
    to parent: JSValue,
    replace: Bool = false,
    builder: (JSValue) -> Void = { _ in }
  ) -> JSValue {
    let node = create(element, builder: builder)
    addElement(node, to: parent, replace: replace)
    return node
  }

  static func create(_ element: String, builder: (JSValue) -> Void = { _ in }) -> JSValue {
    let node = doc.createElement(element)
    builder(node)
    return node
  }

  static func addView(_ view: View, to parent: JSValue, replace: Bool = false) {
    addElement(view.body, to: parent, replace: replace)
    view.onAdded()
  }

  static func addElement(_ element: JSValue, to parent: JSValue, replace: Bool = false) {
    if replace {
      _ = parent.replaceChildren(element)
    } else {
      _ = parent.appendChild(element)
    }
  }

  static func alert(_ message: CustomStringConvertible) {
    _ = jsAlert(message.description)
  }
}

@MainActor
protocol View {
  var body: JSValue { get }
  func onAdded()
}
extension View {
  func onAdded() {}
}

extension JSValue {
  func onClick(_ handler: @escaping () -> Void) {
      self.onclick = .object(
        JSClosure { _ in
          handler()
          return .undefined
        }
      )
  }
}