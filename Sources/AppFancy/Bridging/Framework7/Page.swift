//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit
import SwiftNavigation

/// Wrapper that bridges the Framework7 Page widget to Swift.
/// Also enhances the widget with callbacks for certain life-cycle events and observability.
/// https://framework7.io/docs/page
@MainActor
protocol Page: Element {
  /// The unique name of this page.
  var name: String { get }
  /// An optional set of "control" elements that are part of the page, but not defined in the content section. Default is no controls.
  @ElementBuilder var controls: [Element] { get }
  /// The page content.
  @ElementBuilder var content: [Element] { get }
  /// An optional method that is added to the observation list. This is the usual way to define observation code for a page.
  func observing()
  /// An optional method that is invoked to get additional observation tokens to track. This can be used to define additional observation blocks.
  func observables() -> Set<ObserveToken>
  /// An optional method that is invoked before the page is added to the view.
  func willBeAdded()
  /// An optional method that is invoked after a page is added to the view.
  func onAdded()
  /// An optional method that is invoked before a page will be removed from the view.
  func willBeRemoved()
  /// An optional method that is invoked after a page is removed from the view.
  func onRemoved()
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
  func observing() {}
  func observables() -> Set<ObserveToken> { [] }
  func willBeAdded() {}
  func onAdded() {}
  func willBeRemoved() {}
  func onRemoved() {}
}

extension HTMLClass {
  static let page: Self = "page"
  static let pageContent: Self = "page-content"
}
