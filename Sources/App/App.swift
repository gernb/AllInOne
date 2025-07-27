import JavaScriptEventLoop
@preconcurrency import JavaScriptKit

@MainActor
@main
struct App {
  static let doc = JSObject.global.document

  private static let mainView = MainView()
  private static let jsAlert = JSObject.global.alert.function!

  static func main() {
    JavaScriptEventLoop.installGlobalExecutor()
    doc.body.addView(mainView, replace: true)
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
  @MainActor
  func addView(_ view: View, replace: Bool = false) {
    self.addElement(view.body, replace: replace)
    view.onAdded()
  }
  @MainActor
  func addElement(_ element: JSValue, replace: Bool = false) {
    if replace {
      _ = self.replaceChildren(element)
    } else {
      _ = self.appendChild(element)
    }
  }
}

extension Error {
  var message: String {
    String(describing: self)
  }
}