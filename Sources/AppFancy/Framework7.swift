import JavaScriptKit

extension HTMLClass {
  static let title: Self = "title"
}

// MARK: NavBar

struct NavBar: Element {
  let showBackground: Bool
  let content: () -> [Element]

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

  func render() -> JSObject {
    HTML(.div, class: .navbar) {
      if showBackground {
        HTML(.div, class: .navbarBg)
      }
      HTML(.div, class: .navbarInner, containing: content)
    }
    .render()
  }
}

extension HTMLClass {
  static let navbar: Self = "navbar"
  static let navbarBg: Self = "navbar-bg"
  static let navbarInner: Self = "navbar-inner"
}

// MARK: Card

struct Card: Element {
  @ElementBuilder let content: () -> [Element]

  func render() -> JSObject {
    HTML(.div, classes: .card, .cardContentPadding, .cardRaised, .cardOutline) {
      HTML(.div, class: .cardContent, containing: content)
    }
    .render()
  }
}

extension HTMLClass {
  static let card: Self = "card"
  static let cardContentPadding: Self = "card-content-padding"
  static let cardRaised: Self = "card-raised"
  static let cardOutline: Self = "card-outline"
  static let cardContent: Self = "card-content"
}

// MARK: Page

struct Page: Element {
  let name: String
  let content: () -> [Element]

  init(
    name: String,
    @ElementBuilder controls: @escaping () -> [Element] = {[]},
    @ElementBuilder content: @escaping () -> [Element]
  ) {
    self.name = name
    let pageContent = HTML(.div, class: .pageContent, containing: content) as Element
    self.content = {
      controls() + [pageContent]
    }
  }

  func render() -> JSObject {
    HTML(
      .div,
      class: .page,
      builder: { $0[dynamicMember: "data-name"] = .string(name) },
      containing: content
    )
    .render()
  }
}

extension HTMLClass {
  static let page: Self = "page"
  static let pageContent: Self = "page-content"
}