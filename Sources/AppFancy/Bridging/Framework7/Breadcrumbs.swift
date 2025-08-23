//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Breadcrumbs widget to Swift.
/// https://framework7.io/docs/breadcrumbs
struct Breadcrumbs: Element {
  let items: [Element]

  /// Creates a new `Breadcrumbs` widget with the array of items as the content.
  /// - Parameter items: The custom elements for this instance.
  init(_ items: [Element]) {
    self.items = items
  }

  /// Creates a new `Breadcrumbs` widget with the array of strings as the content.
  /// - Parameter items: The text items for this instance.
  init(_ items: [String]) {
    self.init(
      items.map { text in
        HTML(.div) { $1.innerText = .string(text) }
      }
    )
  }

  /// Creates a new `Breadcrumbs` widget with the array of string/icon pairs as the content.
  /// - Parameter items: The pairs of text and optional icons for this instance.
  init(_ items: [(label: String, icon: F7Icon?)]) {
    self.init(
      items.map { (text, icon) in
        HTML(.div) {
          if let icon {
            Icon(icon)
            HTML(.span) {
              $1.style.marginLeft = "5px"
              $1.innerText = .string(text)
            }
          } else {
            HTML(.span) { $1.innerText = .string(text) }
          }
        }
      }
    )
  }

  var body: Element {
    HTML(.div, classes: .breadcrumbs) {
      if let first = items.first {
        let classes: [HTMLClass] = items.count == 1 ? [.breadcrumbsItem, .breadcrumbsItemActive] : [.breadcrumbsItem]
        first.addingClasses(classes)
        for (index, item) in items.enumerated().dropFirst() {
          HTML(.div, classes: .breadcrumbsSeparator)
          let classes: [HTMLClass] = index == (items.count - 1) ? [.breadcrumbsItem, .breadcrumbsItemActive] : [.breadcrumbsItem]
          item.addingClasses(classes)
        }
      }
    }
  }
}

extension HTMLClass {
  static let breadcrumbs: Self = "breadcrumbs"
  static let breadcrumbsItem: Self = "breadcrumbs-item"
  static let breadcrumbsItemActive: Self = "breadcrumbs-item-active"
  static let breadcrumbsSeparator: Self = "breadcrumbs-separator"
}