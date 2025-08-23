//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Navbar widget to Swift.
/// https://framework7.io/docs/navbar
struct NavBar: Element {
  /// Gets the current NavBar associated with this view. May be `nil` if there is no navbar.
  static var current: NavBar.Instance? {
    Environment[NavBar.self]
  }

  let showBackground: Bool
  let content: HTML.Contents

  /// Creates a new `NavBar` instance.
  /// - Parameters:
  ///   - showBackground: Whether or not to show the navbar background; default is to show the background.
  ///   - content: The custom content for this instance.
  init(showBackground: Bool = true, @ElementBuilder content: @escaping HTML.Contents) {
    self.showBackground = showBackground
    self.content = content
  }

  /// Creates a new `NavBar` instance with a text title.
  /// - Parameters:
  ///   - title: The text to show in the "title" slot.
  ///   - showBackground: Whether or not to show the navbar background; default is to show the background.
  init(title: String, showBackground: Bool = true) {
    self.showBackground = showBackground
    self.content = {
      [
        HTML(.div, classes: .title) {
          $1.innerText = .string(title)
        }
      ]
    }
  }

  var body: Element {
    HTML(.div, classes: .navbar) {
      if showBackground {
        HTML(.div, classes: .navbarBg)
      }
      HTML(.div, classes: .navbarInner) {
        HTML(.div, classes: .left) {
          Link(id: backButton, classes: [.back]) {
            HTML(.i, classes: .icon, .iconBack)
            HTML(.span) {
              $1.innerText = "Back"
            }
          }
        }
        content()
        HTML(.div, id: toolbar, classes: .right)
      }
    }
  }

  let toolbar = IdentifiedNode()
  let backButton = IdentifiedNode()
}

extension NavBar: EnvironmentKey {
  static let defaultValue: Instance? = nil

  var instance: Instance {
    .init(backButton: backButton, toolbar: toolbar)
  }

  /// A simplified NavBar instance that allows for operations to be performed on the shared NavBar.
  @MainActor
  struct Instance {
    let backButton: IdentifiedNode
    let toolbar: IdentifiedNode

    /// Shows or hides the back button on the instance.
    /// - Parameter show: Whether to show the back button.
    func showBackButton(_ show: Bool = true) {
      backButton.style.display = show ? "inline" : "none"
    }
    /// Sets (and replaces) the toolbar items displayed in the trailing "slot" on the nav bar.
    /// - Parameter items: The elements to place in the trailing "slot".
    func setToolbarItems(@ElementBuilder items: HTML.Contents) {
      toolbar.clear()
      items().forEach(toolbar.add)
    }
  }
}

extension HTMLClass {
  static let navbar: Self = "navbar"
  static let navbarBg: Self = "navbar-bg"
  static let navbarInner: Self = "navbar-inner"
  static let left: Self = "left"
  static let title: Self = "title"
  static let right: Self = "right"
  static let back: Self = "back"
  static let iconBack: Self = "icon-back"
}
