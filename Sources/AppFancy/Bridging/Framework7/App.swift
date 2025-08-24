//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit
import SwiftNavigation

/// A bridging wrapper that encapsulates the Framework7 app instance.
/// https://framework7.io/docs/app
@MainActor
struct App {
  /// The DOM document instance.
  static let doc = JSObject.global.document
  /// The Framework7 JavaScript app instance.
  static let f7app = JSObject.global.app
  /// The Framework7 JavaScript "dom" function.
  static let dom7 = JSObject.global.Dom7.function!

  /// Keeps track of whether a sheet is currently being displayed.
  static private(set) var currentSheet: (sheet: Element, f7sheet: JSValue)?

  /// This method should be called as early as possible in order to setup the necessary
  /// bridging code the rest of this library uses.
  static func setup() {
    // Right now the only thing we need to setup is the view router.
    View.setup()
  }

  /// Shows a modal app alert using the Framework7 alert dialog.
  /// - Parameters:
  ///   - text: The alert message body.
  ///   - title: (optional) The alert message title.
  ///   - onDismiss: (optional) Callback that is invoked when the alert is dismissed by the user.
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

  /// Shows a modal app confirmation dialog using the Framework7 confirm dialog.
  /// - Parameters:
  ///   - text: The dialog message body.
  ///   - title: (optional) The dialog message title.
  ///   - confirmed: Callback that is invoked when the user confirms the action (selects the "ok" button).
  ///   - cancelled: (optional) Callback that is invoked if the user cancels or dismisses the dialog without confirming.
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

  /// Shows a modal app dialog that asks the user to input some text using the Framework7 prompt dialog.
  /// - Parameters:
  ///   - text: The dialog message body.
  ///   - title: (optional) The dialog message title.
  ///   - defaultValue: The value to prepopulate the text field with; default is an empty string.
  ///   - confirmed: Callback that is invoked when the user confirms the action (selects the "ok" button).
  ///   - cancelled: (optional) Callback that is invoked if the user cancels or dismisses the dialog without confirming.
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

  /// Shows a modal app popover view using the Framework7 Popover widget.
  /// The popover can be dismissed by the user by tapping anywhere outside the popover view.
  /// - Parameters:
  ///   - target: The node that the popover should be "anchored" to. This determines where the popover is displayed.
  ///   - content: The content of the popover.
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

  /// Shows a non-modal app toast using the Framework7 Toast widget
  /// - Parameters:
  ///   - text: The text content of the toast.
  ///   - closeAfter: (optional) Auto-dismisses the toast after the specified timeout; default is no auto-dismiss.
  /// - Returns: The F7 toast instance.
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

  /// Shows a modal sheet using the Framework7 Sheet widget.
  /// - Parameters:
  ///   - sheet: The `Sheet` to show.
  ///   - swipeToClose: Whether or not to enable swipe to close; default is enabled.
  ///   - detents: (optional) Array of detents/breakpoints the sheet can be swiped to.
  /// - Returns: The F7 sheet instance.
  @discardableResult
  static func showSheet(
    _ sheet: Sheet,
    swipeToClose: Bool = true,
    detents: [Double]? = nil
  ) -> JSValue {
    var tokens = Set<ObserveToken>()
    let sheet = sheet
      .environment(View.self, Environment[View.self]) as! ObservableElement
    let node = sheet.render(parentNode: .undefined)
    let params = [
      "el": node,
      "swipeToClose": swipeToClose,
      "on": [
        "open": JSClosure { _ in
          tokens = [observe { sheet.observing() }]
          tokens.formUnion(sheet.observables())
          sheet.willBeAdded()
          return .undefined
        },
        "opened": JSClosure { _ in
          sheet.onAdded()
          return .undefined
        },
        "close": JSClosure { _ in
          sheet.willBeRemoved()
          return .undefined
        },
        "closed": JSClosure { args in
          sheet.onRemoved()
          tokens.removeAll()
          currentSheet = nil
          print(args[0])
          _ = args[0].destroy()
          return .undefined
        },
      ].jsObject()
    ].jsObject()
    if let detents {
      params["breakpoints"] = detents.map { JSValue(floatLiteral: $0) }.jsValue
    }
    let f7sheet = f7app.sheet.create(params)
    _ = f7sheet.open()
    currentSheet = (sheet, f7sheet)
    return f7sheet
  }
}