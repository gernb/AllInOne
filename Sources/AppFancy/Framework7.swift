import JavaScriptKit
import SwiftNavigation

extension Element {
  func frame(maxWidth: Int? = nil, maxHeight: Int? = nil) -> Element {
    guard maxWidth != nil || maxHeight != nil else { return self }
    return HTML(.div) {
      if let maxWidth {
        $1.style.maxWidth = .string("\(maxWidth)px")
      }
      if let maxHeight {
        $1.style.maxHeight = .string("\(maxHeight)px")
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
  static let preloader: Self = "preloader"
}

// MARK: NavBar

struct NavBar: Element {
  let showBackground: Bool
  let content: () -> [Element]

  private static let backButtonId = "backButtonId"
  private static let backButton = HTML(.a, classes: .link, .back) {
    $1.href = "#"
    $1.id = .string(backButtonId)
  } containing: {
    HTML(.i, classes: .icon, .iconBack)
    HTML(.span) {
      $1.innerText = "Back"
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
        $1.innerText = .string(title)
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

  var body: Element {
    let classList = [
      .button,
      Environment[Button.Shape.self].class,
      Environment[Button.Fill.self].class,
      Environment[Button.Size.self].class,
      Environment[Button.Raised.self] ? .buttonRaised : nil,
    ].compactMap { $0 }
    return HTML(.button, classList: classList) {
      $1.innerText = .string(label)
      $1.onClick(action)
    }
  }
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
  enum Raised {}
}
extension Button.Shape: EnvironmentKey {
  static let defaultValue = Self.rect
  var `class`: HTMLClass? {
    switch self {
    case .rect: nil
    case .round: .buttonRound
    }
  }
}
extension Button.Fill: EnvironmentKey {
  static let defaultValue = Self.none
  var `class`: HTMLClass? {
    switch self {
    case .none: nil
    case .tonal: .buttonTonal
    case .solid: .buttonFill
    case .outline: .buttonOutline
    }
  }
}
extension Button.Size: EnvironmentKey {
  static let defaultValue = Self.normal
  var `class`: HTMLClass? {
    switch self {
    case .small: .buttonSmall
    case .normal: nil
    case .large: .buttonLarge
    }
  }
}
extension Button.Raised: EnvironmentKey {
  static let defaultValue = false
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

extension Element {
  func buttonStyle(
    fill: Button.Fill? = nil,
    raised: Bool? = nil,
    shape: Button.Shape? = nil,
    size: Button.Size? = nil
  ) -> Element {
    var result: Element = self
    if let fill {
      result = result.environment(Button.Fill.self, fill)
    }
    if let raised {
      result = result.environment(Button.Raised.self, raised)
    }
    if let shape {
      result = result.environment(Button.Shape.self, shape)
    }
    if let size {
      result = result.environment(Button.Size.self, size)
    }
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
      class: .page,
      builder: { $1.dataset.name = .string(name) },
      containing: {
        controls + [
          HTML(.div, class: .pageContent, containing: { content })
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

enum Transition: String {
  case circle = "f7-circle"
  case cover = "f7-cover"
  case verticalCover = "f7-cover-v"
  case dive = "f7-dive"
  case fade = "f7-fade"
  case flip = "f7-flip"
  case parallax = "f7-parallax"
  case push = "f7-push"
}

// MARK: Pull-to-refresh

struct PullToRefresh: Element {
  let action: () async -> Void

  var body: Element {
    HTML(.div, class: .ptrPreloader) { parentNode, _ in
      assert(parentNode.className.string == HTMLClass.pageContent.rawValue)
      _ = parentNode.classList.add(HTMLClass.pagePullToRefresh.rawValue)
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
  static let ptrPreloader: Self = "ptr-preloader"
  static let ptrArrow: Self = "ptr-arrow"
  static let pagePullToRefresh: Self = "ptr-content"
}