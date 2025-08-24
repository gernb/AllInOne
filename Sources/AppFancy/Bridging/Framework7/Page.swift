//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Page widget to Swift.
/// https://framework7.io/docs/page
@MainActor
protocol Page: ObservableElement {
  /// The unique name of this page.
  var name: String { get }
  /// An optional set of "control" elements that are part of the page, but not defined in the content section. Default is no controls.
  @ElementBuilder var controls: [Element] { get }
  /// The page content.
  @ElementBuilder var content: [Element] { get }
}

extension Page {
  var controls: [Element] { [] }
  var body: Element {
    HTML(
      .div,
      classes: .page,
      builder: { $1.dataset.name = .string(name) },
      containing: {
        controls + [
          HTML(.div, classes: .pageContent, containing: { content })
        ]
      }
    )
  }
}

extension HTMLClass {
  static let page: Self = "page"
  static let pageContent: Self = "page-content"
}
