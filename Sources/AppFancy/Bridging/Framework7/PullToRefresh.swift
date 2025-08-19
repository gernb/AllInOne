import JavaScriptKit

struct PullToRefresh: Element {
  let action: () async -> Void

  var body: Element {
    HTML(.div, class: .ptrPreloader) { parentNode, _ in
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
      HTML(.div, class: .preloader)
      HTML(.div, class: .ptrArrow)
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