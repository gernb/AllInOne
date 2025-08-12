import JavaScriptKit
import SwiftNavigation

extension HTMLClass {
  static let title: Self = "title"
  static let link: Self = "link"
  static let back: Self = "back"
  static let icon: Self = "icon"
  static let iconBack: Self = "icon-back"
}

// MARK: NavBar

struct NavBar: Element {
  let showBackground: Bool
  let content: () -> [Element]

  private static let backButtonId = "backButtonId"
  private static let backButton = HTML(.a, classes: .link, .back) {
    $0.href = "#"
    $0.id = .string(backButtonId)
  } containing: {
    HTML(.i, classes: .icon, .iconBack)
    HTML(.span) {
      $0.innerText = "Back"
    }
  }

  static func showBackButton(_ show: Bool = true) {
    let backButton = App.doc.getElementById(NavBar.backButtonId)
    backButton.style.display = show ? "inline" : "none"
  }

  init(showBackground: Bool = true, @ElementBuilder content: @escaping () -> [Element]) {
    self.showBackground = showBackground
    self.content = content
  }

  init(title: String, showBackground: Bool = true) {
    self.showBackground = showBackground
    self.content = {[
      HTML(.div, class: .title) {
        $0.innerText = .string(title)
      }
    ]}
  }

  var body: Element {
    HTML(.div, class: .navbar) {
      if showBackground {
        HTML(.div, class: .navbarBg)
      }
      HTML(.div, class: .navbarInner) {
        HTML(.div, class: .left) {
          Self.backButton
        }
        content()
        HTML(.div, class: .right)
      }
    }
  }
}

extension HTMLClass {
  static let navbar: Self = "navbar"
  static let navbarBg: Self = "navbar-bg"
  static let navbarInner: Self = "navbar-inner"
  static let left: Self = "left"
  static let right: Self = "right"
}

// MARK: Card

struct Card: Element {
  @ElementBuilder let content: () -> [Element]

  var body: Element {
    HTML(.div, classes: .card, .cardContentPadding, .cardRaised, .cardOutline) {
      HTML(.div, class: .cardContent, containing: content)
    }
  }
}

extension HTMLClass {
  static let card: Self = "card"
  static let cardContentPadding: Self = "card-content-padding"
  static let cardRaised: Self = "card-raised"
  static let cardOutline: Self = "card-outline"
  static let cardContent: Self = "card-content"
}

// MARK: Button

struct Button: Element {
  let label: String
  let action: () -> Void
  let classes: [HTMLClass] = [.button, .buttonFill, .buttonRound]

  var body: Element {
    HTML(.button, classList: classes) {
      $0.innerText = .string(label)
      $0.onClick(action)
    }
  }
}

extension HTMLClass {
  static let button: Self = "button"
  static let buttonFill: Self = "button-fill"
  static let buttonRound: Self = "button-round"
}

// MARK: Page

@MainActor
protocol Page: Element {
  var name: String { get }
  @ElementBuilder var controls: [Element] { get }
  @ElementBuilder var content: [Element] { get }
  func observing()
  func observables() -> Set<ObserveToken>
  func onAdded()
  func onRemoved()
}
extension Page {
  var controls: [Element] { [] }
  var body: Element {
    HTML(
      .div,
      class: .page,
      builder: { $0.dataset.name = .string(name) },
      containing: {
        controls + [
          HTML(.div, class: .pageContent, containing: { content })
        ]
      }
    )
  }
  func observing() {}
  func observables() -> Set<ObserveToken> { [] }
  func onAdded() {}
  func onRemoved() {}
}

extension HTMLClass {
  static let page: Self = "page"
  static let pageContent: Self = "page-content"
}