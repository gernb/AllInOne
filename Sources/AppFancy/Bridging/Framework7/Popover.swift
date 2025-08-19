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
    HTML(.a, classes: .link, .popoverOpen) {
      $1.href = "#"
      $1.dataset.popover = .string("." + instance)
    } containing: {
      label()
      HTML(.div, classes: .popover, .class(instance)) {
        HTML(.div, class: .popoverInner, containing: content)
      }
      .environment(InsidePopover.self, true)
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
}