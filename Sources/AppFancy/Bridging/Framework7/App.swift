import JavaScriptKit

@MainActor
struct App {
  static let doc = JSObject.global.document
  static let f7app = JSObject.global.app
  static let dom7 = JSObject.global.Dom7.function!

  static func setup() {
    View.setup()
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

  static func showPopover(relativeTo target: IdentifiedNode, @ElementBuilder content: @escaping HTML.Contents) {
    let node = HTML(.div, classes: .popover) {
      HTML(.div, classes: .popoverArrow)
      HTML(.div, classes: .popoverInner, containing: content)
        .environment(Popover.InsidePopover.self, true)
    }
    .render(parentNode: .undefined)
    let popover = f7app.popover.create([
      "el": node,
      "targetEl": target.node,
      "on": [
        "closed": JSClosure { args in
          let popover = args[0]
          _ = popover.destroy()
          return .undefined
        }
      ]
    ].jsObject())
    _ = popover.open()
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