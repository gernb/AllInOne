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
  static let iconBack: Self = "icon-back"
  static let preloader: Self = "preloader"
}

// MARK: Block

struct Block: Element {
  let styles: [Style]
  let content: () -> [Element]

  init(styles: [Style], @ElementBuilder content: @escaping () -> [Element]) {
    self.styles = styles
    self.content = content
  }

  init(style: Style..., @ElementBuilder content: @escaping () -> [Element]) {
    self.init(styles: style, content: content)
  }

  init(@ElementBuilder content: @escaping () -> [Element]) {
    self.init(styles: [], content: content)
  }

  var body: Element {
    HTML(
      .div,
      classList: [.block] + styles.map(\.class),
      containing: content
    )
  }
}
extension Block {
  enum Style {
    case strong, outline, inset
    var `class`: HTMLClass {
      switch self {
      case .strong: .blockStrong
      case .outline: .blockOutline
      case .inset: .inset
      }
    }
  }
}

struct BlockFooter: Element {
  @ElementBuilder var content: () -> [Element]
  var body: Element {
    HTML(.div, class: .blockFooter, containing: content)
  }
}

extension HTMLClass {
  static let block: Self = "block"
  static let blockStrong: Self = "block-strong"
  static let blockOutline: Self = "block-outline"
  static let inset: Self = "inset"
  static let blockFooter: Self = "block-footer"
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
      _ = $1.addEventListener(
        "click",
        JSClosure { _ in
          action()
          return .undefined
        }
      )
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
  static let ptrPreloader: Self = "ptr-preloader"
  static let ptrArrow: Self = "ptr-arrow"
  static let ptrWatchScrollable: Self = "ptr-watch-scrollable"
  static let pagePullToRefresh: Self = "ptr-content"
}

// MARK: Breadcrumbs

struct Breadcrumbs: Element {
  let items: [Element]

  init(_ items: [Element]) {
    self.items = items
  }
  init(_ items: [String]) {
    self.init(
      items.map { text in
        HTML(.div) { $1.innerText = .string(text) }
      }
    )
  }
  init(_ items: [(label: String, icon: F7Icon?)]) {
    self.init(
      items.map { (text, icon) in
        HTML(.div) {
          if let icon {
            Icon(icon)
            HTML(.span) {
              $1.style.marginLeft = "5px"
              $1.innerText = .string(text)
            }
          } else {
            HTML(.span) { $1.innerText = .string(text) }
          }
        }
      }
    )
  }

  var body: Element {
    HTML(.div, class: .breadcrumbs) {
      if let first = items.first {
        let classes: [HTMLClass] = items.count == 1 ? [.breadcrumbsItem, .breadcrumbsItemActive] : [.breadcrumbsItem]
        first.addingClasses(classes)
        for (index, item) in items.enumerated().dropFirst() {
          HTML(.div, class: .breadcrumbsSeparator)
          let classes: [HTMLClass] = index == (items.count - 1) ? [.breadcrumbsItem, .breadcrumbsItemActive] : [.breadcrumbsItem]
          item.addingClasses(classes)
        }
      }
    }
  }
}

extension HTMLClass {
  static let breadcrumbs: Self = "breadcrumbs"
  static let breadcrumbsItem: Self = "breadcrumbs-item"
  static let breadcrumbsItemActive: Self = "breadcrumbs-item-active"
  static let breadcrumbsSeparator: Self = "breadcrumbs-separator"
}

// MARK: Icons

struct Icon: Element {
  let icon: String

  init(_ icon: String) {
    self.icon = icon
  }
  init(_ icon: F7Icon) {
    self.init(icon.rawValue)
  }
  init(_ icon: any RawRepresentable<String>) {
    self.init(icon.rawValue)
  }

  var body: Element {
    HTML(.span) {
      HTML(.i, classes: .icon, .f7Icons, .ifNotMD) {
        $1.innerText = .string(icon)
      }
      HTML(.i, classes: .icon, .materialIcons, .mdOnly) {
        $1.innerText = .string(icon)
      }
    }
  }
}

extension HTMLClass {
  static let icon: Self = "icon"
  static let f7Icons: Self = "f7-icons"
  static let materialIcons: Self = "material-icons"
  static let ifNotMD: Self = "if-not-md"
  static let mdOnly: Self = "md-only"
}

enum F7Icon: String {
  case docPlaintext = "doc_plaintext"
  case docText = "doc_text"
  case docTextFill = "doc_text_fill"
  case folder
  case folderFill = "folder_fill"
  case house
}

// MARK: List / Swipeout

struct List: Element {
  let id: HTMLId?
  let content: () -> [Element]

  init(id: HTMLId? = nil, @ElementBuilder content: @escaping () -> [Element] = {[]}) {
    self.id = id
    self.content = content
  }

  var body: Element {
    HTML(.div, class: .list) {
      HTML(.ul, id: id, containing: content)
    }
  }
}

extension List {
  struct Item: Element {
    let id: HTMLId?
    let title: String
    let subtitle: String?
    let icon: Icon?
    let leadingSwipeActions: [SwipeAction]
    let trailingSwipeActions: [SwipeAction]
    let action: (() -> Void)?

    private var hasSwipeOut: Bool {
      leadingSwipeActions.isEmpty == false || trailingSwipeActions.isEmpty == false
    }

    init(
      id: HTMLId? = nil,
      title: String,
      subtitle: String? = nil,
      icon: F7Icon? = nil,
      leadingSwipeActions: [SwipeAction] = [],
      trailingSwipeActions: [SwipeAction] = [],
      action: (() -> Void)? = nil
    ) {
      self.id = id
      self.title = title
      self.subtitle = subtitle
      self.icon = icon.map { Icon($0) }
      self.leadingSwipeActions = leadingSwipeActions
      self.trailingSwipeActions = trailingSwipeActions
      self.action = action
    }

    var body: Element {
      HTML(.li, id: id, classList: hasSwipeOut ? [.swipeout] : []) {
        if let action {
          HTML(.a, classList: hasSwipeOut ? [.itemLink, .itemContent, .swipeoutContent] : [.itemLink, .itemContent]) {
            $1.href = "#"
            _ = $1.addEventListener(
              "click",
              JSClosure { _ in
                action()
                return .undefined
              }
            )
          } containing: {
            content
          }
        } else {
          HTML(.div, classList: hasSwipeOut ? [.itemContent, .swipeoutContent] : [.itemContent]) {
            content
          }
        }
      }
    }

    @ElementBuilder
    private var content: [Element] {
      if let icon {
        HTML(.div, class: .itemMedia) {
          icon
        }
        HTML(.div, class: .itemInner) {
          HTML(.div, class: .itemTitle) { $1.innerText = .string(title) }
          if let subtitle {
            HTML(.div, class: .itemAfter) { $1.innerText = .string(subtitle) }
          }
        }
      }
      if leadingSwipeActions.isEmpty == false {
        HTML(.div, class: .swipeoutActionsLeft) {
          for item in leadingSwipeActions {
            HTML(.a, class: .swipeoutClose) {
              $1.href = "#"
              $1.innerText = .string(item.title)
              _ = $1.addEventListener(
                "click",
                JSClosure { _ in
                  item.action()
                  return .undefined
                }
              )
            }
          }
        }
      }
      if trailingSwipeActions.isEmpty == false {
        HTML(.div, class: .swipeoutActionsRight) {
          for item in trailingSwipeActions {
            HTML(.a, class: .swipeoutClose) {
              $1.href = "#"
              $1.innerText = .string(item.title)
              _ = $1.addEventListener(
                "click",
                JSClosure { _ in
                  item.action()
                  return .undefined
                }
              )
            }
          }
        }
      }
    }
  }

  struct SwipeAction {
    let title: String
    let action: () -> Void
  }
}

extension HTMLClass {
  static let list: Self = "list"
  static let itemContent: Self = "item-content"
  static let itemMedia: Self = "item-media"
  static let itemInner: Self = "item-inner"
  static let itemTitle: Self = "item-title"
  static let itemAfter: Self = "item-after"
  static let itemLink: Self = "item-link"
  static let swipeout: Self = "swipeout"
  static let swipeoutContent: Self = "swipeout-content"
  static let swipeoutActionsLeft: Self = "swipeout-actions-left"
  static let swipeoutActionsRight: Self = "swipeout-actions-right"
  static let swipeoutClose: Self = "swipeout-close"
}