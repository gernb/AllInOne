//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Toolbar widget to Swift.
/// https://framework7.io/docs/toolbar-tabbar
struct Toolbar: Element {
  /// Gets the current Toolbar associated with this view. May be `nil` if there is no toolbar.
  static var current: Toolbar.Instance? {
    Environment[Toolbar.self]
  }

  let content: HTML.Contents

  /// Creates a new `Toolbar` instance.
  /// - Parameters:
  ///   - content: The custom content for this instance.
  init(@ElementBuilder content: @escaping HTML.Contents = {[]}) {
    self.content = content
  }

  var body: Element {
    HTML(.div, id: toolbarNode, classes: .toolbar, .toolbarBottom) {
      HTML(.div, id: contentNode, classes: .toolbarInner) {
        content()
      }
    }
  }

  let toolbarNode = IdentifiedNode()
  let contentNode = IdentifiedNode()
}

extension Toolbar: EnvironmentKey {
  static let defaultValue: Instance? = nil

  var instance: Instance {
    .init(toolbar: toolbarNode, content: contentNode)
  }

  /// A simplified Toolbar instance that allows for operations to be performed on the shared instance.
  @MainActor
  struct Instance {
    let toolbar: IdentifiedNode
    let content: IdentifiedNode

    /// Hide this toolbar
    func hide() {
      _ = App.f7app.toolbar.hide(toolbar.node)
    }

    /// Show this toolbar
    func show() {
      _ = App.f7app.toolbar.show(toolbar.node)
    }
  }
}

extension HTMLClass {
  static let toolbar: Self = "toolbar"
  static let toolbarBottom: Self = "toolbar-bottom"
  static let toolbarInner: Self = "toolbar-inner"
}
