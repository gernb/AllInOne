//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Pull to Refresh control to Swift.
/// https://framework7.io/docs/pull-to-refresh
struct PullToRefresh: Element {
  /// The callback to invoke when the pull-to-refresh control is actioned (pulled).
  /// When the action returns the spinner will be dismissed.
  let action: () async -> Void

  var body: Element {
    HTML(.div, classes: .ptrPreloader) { parentNode, _ in
      assert(parentNode.className.string == HTMLClass.pageContent.rawValue)
      _ = parentNode.classList.add(HTMLClass.pagePullToRefresh.rawValue)
      parentNode.dataset.ptrMousewheel = .boolean(true)
      _ = App.dom7(parentNode).on(
        "ptr:refresh",
        JSClosure { args in
          let done = args[1].function!
          Task {
            await action()
            done()
          }
          return .undefined
        }
      )
    } containing: {
      HTML(.div, classes: .preloader)
      HTML(.div, classes: .ptrArrow)
    }
  }
}

extension HTMLClass {
  static let preloader: Self = "preloader"
  static let ptrPreloader: Self = "ptr-preloader"
  static let ptrArrow: Self = "ptr-arrow"
  static let ptrWatchScrollable: Self = "ptr-watch-scrollable"
  static let pagePullToRefresh: Self = "ptr-content"
}