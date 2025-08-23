//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Link control to Swift.
/// https://framework7.io/docs/link
struct Link: Element {
  let id: HTMLId?
  let classes: [HTMLClass]
  let content: HTML.Contents
  let action: (() -> Void)?

  /// Creates a new `Link` with the provided text label.
  /// - Parameters:
  ///   - label: The text label for this instance.
  ///   - id: (optional) The unique ID for this instance.
  ///   - classes: (optional) HTML classes to add to this instance.
  ///   - action: Callback that is invoked when the user actions (taps/clicks) on this control.
  init(
    _ label: String,
    id: HTMLId? = nil,
    classes: [HTMLClass] = [],
    action: @escaping () -> Void
  ) {
    self.init(id: id, classes: classes, action: action) {
      HTML(.span) {
        $1.innerText = .string(label)
      }
    }
  }

  /// Creates a new `Link` with custom content.
  /// - Parameters:
  ///   - id: (optional) The unique ID for this instance.
  ///   - action: Callback that is invoked when the user actions (taps/clicks) on this control.
  ///   - content: The custom content for the label of this control.
  init(
    id: HTMLId? = nil,
    action: @escaping () -> Void,
    @ElementBuilder content: @escaping HTML.Contents
  ) {
    self.init(id: id, classes: [], action: action, content: content)
  }

  /// Creates a new `Link` with custom content and additional HTML classes added to the link node.
  /// - Parameters:
  ///   - id: (optional) The unique ID for this instance.
  ///   - classes: Array of additional HTML classes to add to the link node.
  ///   - action: Callback that is invoked when the user actions (taps/clicks) on this control.
  ///   - content: The custom content for the label of this control.
  init(
    id: HTMLId? = nil,
    classes: [HTMLClass],
    action: (() -> Void)? = nil,
    @ElementBuilder content: @escaping HTML.Contents
  ) {
    self.id = id
    self.classes = classes
    self.action = action
    self.content = content
  }

  var body: Element {
    HTML(
      .a,
      id: id,
      classList: classList,
      builder: {
        $1.href = "#"
        if let action {
          _ = $1.addEventListener(
            "click",
            JSClosure { _ in
              action()
              return .undefined
            }
          )
        }
      },
      containing: content
    )
  }

  private var classList: [HTMLClass] {
    if Environment[Popover.InsidePopover.self] {
      [.link, .popoverClose] + classes
    } else {
      [.link] + classes
    }
  }
}

extension HTMLClass {
  static let link: Self = "link"
}
