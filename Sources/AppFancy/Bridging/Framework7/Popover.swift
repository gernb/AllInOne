//
// Copyright © 2025 peter bohac. All rights reserved.
//

import Foundation
import JavaScriptKit

/// Wrapper that bridges the Framework7 Popover control to Swift.
/// This is a UI element that provides an actionable element that displays a popover when tapped.
/// https://framework7.io/docs/popover
struct Popover: Element {
  let label: HTML.Contents
  let content: HTML.Contents
  let instance = "my-popover-" + UUID().uuidString.replacingOccurrences(of: "-", with: "")

  /// Creates a new `Popover` instance.
  /// - Parameters:
  ///   - label: The custom UI content for the label.
  ///   - content: The custom content to display in the popover.
  init(
    @ElementBuilder label: @escaping HTML.Contents,
    @ElementBuilder content: @escaping HTML.Contents
  ) {
    self.label = label
    self.content = content
  }

  /// Creates a new `Popover` instance with a text label.
  /// - Parameters:
  ///   - label: The text to display in the element that user taps on to display the popover.
  ///   - content: The custom content to display in the popover.
  init(
    _ label: String,
    @ElementBuilder content: @escaping HTML.Contents
  ) {
    self.label = { [HTML(.span) { $1.innerText = .string(label) }] }
    self.content = content
  }

  var body: Element {
    let popoverTarget = IdentifiedNode()
    return Link(id: popoverTarget) {
      App.showPopover(relativeTo: popoverTarget, content: content)
    } content: {
      label()
    }
  }
}

extension Popover {
  /// This is used to inform other controls when they are inside a popover so they can adapt if necessary.
  struct InsidePopover: EnvironmentKey {
    static let defaultValue = false
  }
}

extension HTMLClass {
  static let popover: Self = "popover"
  static let popoverOpen: Self = "popover-open"
  static let popoverClose: Self = "popover-close"
  static let popoverInner: Self = "popover-inner"
  static let popoverArrow: Self = "popover-arrow"
}