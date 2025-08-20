import JavaScriptKit
import SwiftNavigation

@MainActor
protocol Page: Element {
  var name: String { get }
  @ElementBuilder var controls: [Element] { get }
  @ElementBuilder var content: [Element] { get }
  func observing()
  func observables() -> Set<ObserveToken>
  func willBeAdded()
  func onAdded()
  func willBeRemoved()
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
