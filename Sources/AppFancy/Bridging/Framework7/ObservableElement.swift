//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit
import SwiftNavigation

/// An `Element` that is enhanced with observability and certain life-cycle events.
@MainActor
protocol ObservableElement: Element {
  /// An optional method that is added to the observation list. This is the usual way to define observation code for an element.
  func observing()
  /// An optional method that is invoked to get additional observation tokens to track. This can be used to define additional observation blocks.
  func observables() -> Set<ObserveToken>
  /// An optional method that is invoked before the element is added to the view.
  func willBeAdded()
  /// An optional method that is invoked after the element is added to the view.
  func onAdded()
  /// An optional method that is invoked before the element will be removed from the view.
  func willBeRemoved()
  /// An optional method that is invoked after the element is removed from the view.
  func onRemoved()
}

extension ObservableElement {
  func observing() {}
  func observables() -> Set<ObserveToken> { [] }
  func willBeAdded() {}
  func onAdded() {}
  func willBeRemoved() {}
  func onRemoved() {}
}