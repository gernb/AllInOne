import JavaScriptKit
import SwiftNavigation

extension Element {
  func frame(maxWidth: Int? = nil, maxHeight: Int? = nil) -> Element {
    guard maxWidth != nil || maxHeight != nil else { return self }
    return HTML(.div) {
      if let maxWidth {
        $0.style.maxWidth = .string("\(maxWidth)px")
      }
      if let maxHeight {
        $0.style.maxHeight = .string("\(maxHeight)px")
      }
    } containing: {
      self
    }
  }
}

extension HTMLClass {
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
  static let title: Self = "title"
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
  var classes: [HTMLClass] = [.button]

  var body: Element {
    HTML(.button, classList: classes) {
      $0.innerText = .string(label)
      $0.onClick(action)
    }
  }
}

extension HTMLClass {
  static let button: Self = "button"
  static let buttonTonal: Self = "button-tonal"
  static let buttonFill: Self = "button-fill"
  static let buttonOutline: Self = "button-outline"
  static let buttonRound: Self = "button-round"
  static let buttonRaised: Self = "button-raised"
  static let buttonSmall: Self = "button-small"
  static let buttonLarge: Self = "button-large"
}

extension Button {
  enum Shape {
    case rect, round
  }
  enum Fill {
    case none, tonal, solid, outline
  }
  enum Size {
    case small, normal, large
  }

  func buttonStyle(
    fill: Fill? = nil,
    raised: Bool? = nil,
    shape: Shape? = nil,
    size: Size? = nil
  ) -> Self {
    var classes = Set(self.classes)
    switch shape {
    case .rect: classes.remove(.buttonRound)
    case .round: classes.insert(.buttonRound)
    case .none: break
    }
    switch fill {
    case .some(.none):
      classes.remove(.buttonTonal)
      classes.remove(.buttonFill)
      classes.remove(.buttonOutline)
    case .tonal:
      classes.insert(.buttonTonal)
      classes.remove(.buttonFill)
      classes.remove(.buttonOutline)
    case .solid:
      classes.remove(.buttonTonal)
      classes.insert(.buttonFill)
      classes.remove(.buttonOutline)
    case .outline:
      classes.remove(.buttonTonal)
      classes.remove(.buttonFill)
      classes.insert(.buttonOutline)
    case nil:
      break
    }
    switch raised {
    case .some(true): classes.insert(.buttonRaised)
    case .some(false): classes.remove(.buttonRaised)
    case .none: break
    }
    switch size {
    case .small:
      classes.insert(.buttonSmall)
      classes.remove(.buttonLarge)
    case .normal:
      classes.remove(.buttonSmall)
      classes.remove(.buttonLarge)
    case .large:
      classes.remove(.buttonSmall)
      classes.insert(.buttonLarge)
    case .none: break
    }
    var result = self
    result.classes = Array(classes)
    return result
  }
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