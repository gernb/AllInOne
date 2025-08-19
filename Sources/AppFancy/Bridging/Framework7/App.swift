import JavaScriptKit
import SwiftNavigation

@MainActor
struct App {
  static let doc = JSObject.global.document
  static let f7app = JSObject.global.app
  static let dom7 = JSObject.global.Dom7.function!

  static var pages: [String: (page: Page, tokens: Set<ObserveToken>)] = [:]

  static func setup() {
    _ = dom7(doc).on(
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
    _ = dom7(doc).on(
      "page:afterin",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        pages[name]?.page.onAdded()
        return .undefined
      }
    )
    _ = dom7(doc).on(
      "page:beforeout",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        pages[name]?.page.willBeRemoved()
        return .undefined
      }
    )
    _ = dom7(doc).on(
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
    _ = dom7(doc).on(
      "page:beforeremove",
      JSClosure { args in
        let f7page = args[1].object!
        let name = f7page.name.string!
        pages[name] = nil
        return .undefined
      }
    )
  }

  static func showAlert(text: String, title: String? = nil, onDismiss: @escaping () -> Void = {}) {
    _ = f7app.dialog.alert(
      text,
      title,
      JSClosure { _ in
        onDismiss()
        return .undefined
      }
    )
  }

  static func showConfirmDialog(
    text: String,
    title: String? = nil,
    confirmed: @escaping () -> Void,
    cancelled: @escaping () -> Void = {}
  ) {
    _ = f7app.dialog.confirm(
      text,
      title,
      JSClosure { _ in
        confirmed()
        return .undefined
      },
      JSClosure { _ in
        cancelled()
        return .undefined
      }
    )
  }

  static func showPrompt(
    text: String,
    title: String? = nil,
    defaultValue: String = "",
    confirmed: @escaping (String) -> Void,
    cancelled: @escaping () -> Void = {}
  ) {
    _ = f7app.dialog.prompt(
      text,
      title,
      JSClosure { args in
        let value = args[0].string!
        confirmed(value)
        return .undefined
      },
      JSClosure { _ in
        cancelled()
        return .undefined
      },
      defaultValue
    )
  }

  @discardableResult
  static func showToast(text: String, closeAfter: Duration? = nil) -> JSValue {
    let params = JSObject()
    params.text = .string(text)
    if let closeAfter {
      let closeTimeout = Double(closeAfter.components.seconds * 1000)
      params.closeTimeout = .number(closeTimeout)
    }
    return f7app.toast.show(params)
  }
}