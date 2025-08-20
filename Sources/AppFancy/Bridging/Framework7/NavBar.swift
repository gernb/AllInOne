import JavaScriptKit

struct NavBar: Element {
  static var current: NavBar.Instance? {
    Environment[NavBar.self]
  }

  let showBackground: Bool
  let content: HTML.Contents

  init(showBackground: Bool = true, @ElementBuilder content: @escaping HTML.Contents) {
    self.showBackground = showBackground
    self.content = content
  }

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

  @MainActor
  struct Instance {
    let backButton: IdentifiedNode
    let toolbar: IdentifiedNode

    func showBackButton(_ show: Bool = true) {
      backButton.style.display = show ? "inline" : "none"
    }
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
