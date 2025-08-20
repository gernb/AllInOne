import Foundation
import JavaScriptKit

struct Popover: Element {
  let label: () -> [Element]
  let content: () -> [Element]
  let instance = "my-popover-" + UUID().uuidString.replacingOccurrences(of: "-", with: "")

  init(
    @ElementBuilder label: @escaping () -> [Element],
    @ElementBuilder content: @escaping () -> [Element]
  ) {
    self.label = label
    self.content = content
  }

  init(
    _ label: String,
    @ElementBuilder content: @escaping () -> [Element]
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