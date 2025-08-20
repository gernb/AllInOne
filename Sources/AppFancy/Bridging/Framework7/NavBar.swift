import JavaScriptKit

struct NavBar: Element {
  static var current: NavBar.Instance? {
    Environment[NavBar.self]
  }

  let showBackground: Bool
  let content: () -> [Element]

  init(showBackground: Bool = true, @ElementBuilder content: @escaping () -> [Element]) {
    self.showBackground = showBackground
    self.content = content
  }

  init(title: String, showBackground: Bool = true) {
    self.showBackground = showBackground
    self.content = {
      [
        HTML(.div, class: .title) {
          $1.innerText = .string(title)
        }
      ]
    }
  }

  var body: Element {
    HTML(.div, class: .navbar) {
      if showBackground {
        HTML(.div, class: .navbarBg)
      }
      HTML(.div, class: .navbarInner) {
        HTML(.div, class: .left) {
          Link(id: backButton, classes: [.back]) {
            HTML(.i, classes: .icon, .iconBack)
            HTML(.span) {
              $1.innerText = "Back"
            }
          }
        }
        content()
        HTML(.div, id: toolbar, class: .right)
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
    func setToolbarItems(@ElementBuilder items: () -> [Element]) {
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
