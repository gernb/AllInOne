import Foundation
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
          Link(id: Self.backButton, classes: [.back]) {
            HTML(.i, classes: .icon, .iconBack)
            HTML(.span) {
              $1.innerText = "Back"
            }
          }
        }
        content()
        HTML(.div, id: Self.toolbar, class: .right)
      }
    }
  }

  static let toolbar = IdentifiedNode()
  static let backButton = IdentifiedNode()

  static func showBackButton(_ show: Bool = true) {
    backButton.style.display = show ? "inline" : "none"
  }
  static func setToolbarItems(@ElementBuilder items: () -> [Element]) {
    toolbar.clear()
    items().forEach(toolbar.add)
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

// MARK: Link

struct Link: Element {
  let id: HTMLId?
  let classes: [HTMLClass]
  let content: () -> [Element]
  let action: (() -> Void)?

  init(
    _ label: String,
    id: HTMLId? = nil,
    classes: [HTMLClass] = [],
    action: @escaping () -> Void
  ) {
    self.init(id: id, classes: classes, action: action) {
      HTML(.span) {
        $1.innerText = .string(label)
      }
    }
  }

  init(
    id: HTMLId? = nil,
    action: @escaping () -> Void,
    @ElementBuilder content: @escaping () -> [Element]
  ) {
    self.init(id: id, classes: [], action: action, content: content)
  }

  fileprivate init(
    id: HTMLId? = nil,
    classes: [HTMLClass],
    action: (() -> Void)? = nil,
    @ElementBuilder content: @escaping () -> [Element]
  ) {
    self.id = id
    self.classes = classes
    self.action = action
    self.content = content
  }

  var body: Element {
    HTML(
      .a,
      id: id,
      classList: classList,
      builder: {
        $1.href = "#"
        if let action {
          _ = $1.addEventListener(
            "click",
            JSClosure { _ in
              action()
              return .undefined
            }
          )
        }
      },
      containing: content
    )
  }

  private var classList: [HTMLClass] {
    if Environment[Popover.InsidePopover.self] {
      [.link, .popoverClose] + classes
    } else {
      [.link] + classes
    }
  }
}

extension HTMLClass {
  static let link: Self = "link"
}

// MARK: Button

struct Button: Element {
  let label: () -> [Element]
  let action: () -> Void

  init(
    action: @escaping () -> Void,
    @ElementBuilder label: @escaping () -> [Element]
  ) {
    self.label = label
    self.action = action
  }

  init(
    _ label: String,
    action: @escaping () -> Void
  ) {
    self.init(action: action) {
      HTML(.span) { $1.innerText = .string(label) }
    }
  }

  var body: Element {
    let classList = [
      .button,
      Environment[Button.Shape.self].class,
      Environment[Button.Fill.self].class,
      Environment[Button.Size.self].class,
      Environment[Button.Raised.self] ? .buttonRaised : nil,
      Environment[Popover.InsidePopover.self] ? .popoverClose : nil,
    ].compactMap { $0 }
    return HTML(
      .button,
      classList: classList,
      builder: {
        _ = $1.addEventListener(
          "click",
          JSClosure { _ in
            action()
            return .undefined
          }
        )
      },
      containing: label
    )
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
  case arrowUpDoc = "arrow_up_doc"
  case arrowUpDocFill = "arrow_up_doc_fill"
  case docPlaintext = "doc_plaintext"
  case docText = "doc_text"
  case docTextFill = "doc_text_fill"
  case ellipsis
  case folder
  case folderBadgePlus = "folder_badge_plus"
  case folderFill = "folder_fill"
  case folderFillBadgePlus = "folder_fill_badge_plus"
  case house
  case lineHorizontal3 = "line_horizontal_3"
}

// MARK: Colours

enum ThemeColor {
  case primary, white, black
  case red, green, blue
  case lightBlue
  case pink, yellow, teal, lime
  case orange, deepOrange
  case purple, deepPurple

  var `class`: HTMLClass {
    switch self {
    case .primary: "color-primary"
    case .white: "color-white"
    case .black: "color-black"
    case .red: "color-red"
    case .green: "color-green"
    case .blue: "color-blue"
    case .lightBlue: "color-lightblue"
    case .pink: "color-pink"
    case .yellow: "color-yellow"
    case .teal: "color-teal"
    case .lime: "color-lime"
    case .orange: "color-orange"
    case .deepOrange: "color-deeporange"
    case .purple: "color-purple"
    case .deepPurple: "color-deeppurple"
    }
  }
}

// MARK: List

struct List: Element {
  let id: HTMLId?
  let content: () -> [Element]

  init(id: HTMLId? = nil, @ElementBuilder content: @escaping () -> [Element] = {[]}) {
    self.id = id
    self.content = content
  }

  var body: Element {
    HTML(.div, classList: classList) {
      HTML(.ul, id: id, containing: content)
    }
  }

  private var classList: [HTMLClass] {
    if let style = Environment[Style.self] {
      [.list, style.class]
    } else {
      [.list]
    }
  }
}
extension List {
  enum Style: EnvironmentKey {
    case itemDividers, outline
    static let defaultValue: Style? = nil
    var `class`: HTMLClass {
      switch self {
      case .itemDividers: .listDividers
      case .outline: .listOutline
      }
    }
  }
}

extension Element {
  func listStyle(_ style: List.Style?) -> Element {
    self.environment(List.Style.self, style)
  }
}

protocol ListItemElement: Element {}

struct ListItem: ListItemElement {
  let id: HTMLId?
  let title: String
  let subtitle: String?
  let icon: Icon?

  init(id: HTMLId? = nil, title: String, subtitle: String? = nil, icon: F7Icon? = nil) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.icon = icon.map { Icon($0) }
  }

  var body: Element {
    HTML(.li, id: id, classList: hasSwipeOut ? [.swipeout] : []) {
      HTML(.div, classList: hasSwipeOut ? [.itemContent, .swipeoutContent] : [.itemContent]) {
        Self.content(title: title, subtitle: subtitle, icon: icon)
      }
    }
  }

  private var hasSwipeOut: Bool { Environment[Swipeout.self].isEmpty == false }

  fileprivate static func content(title: String, subtitle: String?, icon: Icon?) -> [Element] {
    let media = icon.map { icon in
      HTML(.div, class: .itemMedia) {
        icon
      }
    }
    let inner = HTML(.div, class: .itemInner) {
      HTML(.div, class: .itemTitle) { $1.innerText = .string(title) }
      if let subtitle {
        HTML(.div, class: .itemAfter) { $1.innerText = .string(subtitle) }
      }
    }
    let leadingSwipeout = Environment[Swipeout.self]
      .first { $0.edge == .leading && $0.actions.isEmpty == false }
      .map { group in
        HTML(.div, class: .swipeoutActionsLeft) {
          group.actions[0].addingClasses(.swipeoutOverswipe)
          Array(group.actions.dropFirst())
        }
      }
    let trailingSwipeout = Environment[Swipeout.self]
      .first { $0.edge == .trailing && $0.actions.isEmpty == false }
      .map { group in
        HTML(.div, class: .swipeoutActionsRight) {
          Array(group.actions.dropLast())
          group.actions.last!.addingClasses(.swipeoutOverswipe)
        }
      }
    return [media, inner, leadingSwipeout, trailingSwipeout].compactMap { $0 }
  }
}

struct ActionListItem: ListItemElement {
  let id: HTMLId?
  let title: String
  let subtitle: String?
  let icon: Icon?
  let action: () -> Void
  let isItemLink: Bool

  init(
    id: HTMLId? = nil,
    title: String,
    subtitle: String? = nil,
    icon: F7Icon? = nil,
    action: @escaping () -> Void
  ) {
    self.init(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      isItemLink: false,
      action: action
    )
  }

  fileprivate init(
    id: HTMLId? = nil,
    title: String,
    subtitle: String? = nil,
    icon: F7Icon? = nil,
    isItemLink: Bool,
    action: @escaping () -> Void
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.icon = icon.map { Icon($0) }
    self.isItemLink = isItemLink
    self.action = action
  }

  var body: Element {
    var isSwiping = false
    var delay: Task<Void, Never>?
    var swipeIsOpen = false
    return HTML(.li, id: id, classList: hasSwipeOut ? [.swipeout] : []) {
      _ = $1.addEventListener(
        "swipeout",
        JSClosure { _ in
          isSwiping = true
          delay?.cancel()
          delay = Task {
            do {
              try await Task.sleep(for: .milliseconds(100))
              isSwiping = false
            } catch {}
          }
          return .undefined
        }
      )
      _ = $1.addEventListener(
        "swipeout:open",
        JSClosure { _ in
          swipeIsOpen = true
          return .undefined
        }
      )
      _ = $1.addEventListener(
        "swipeout:closed",
        JSClosure { _ in
          swipeIsOpen = false
          return .undefined
        }
      )
    } containing: {
      HTML(.div, classList: classList) {
        $1.style.cursor = "pointer"
        _ = $1.addEventListener(
          "click",
          JSClosure { _ in
            if isSwiping == false && swipeIsOpen == false {
              action()
            }
            return .undefined
          }
        )
      } containing: {
        ListItem.content(title: title, subtitle: subtitle, icon: icon)
      }
    }
  }

  private var classList: [HTMLClass] {
    var list = [HTMLClass.itemContent]
    if hasSwipeOut {
      list.append(.swipeoutContent)
    }
    if isItemLink {
      list.append(.itemLink)
    }
    if Environment[Popover.InsidePopover.self] {
      list.append(.popoverClose)
    }
    return list
  }
  private var hasSwipeOut: Bool { Environment[Swipeout.self].isEmpty == false }
}

struct NavigationListItem: ListItemElement {
  let id: HTMLId?
  let title: String
  let subtitle: String?
  let icon: F7Icon?
  let destination: () -> Page

  init(
    id: HTMLId? = nil,
    title: String,
    subtitle: String? = nil,
    icon: F7Icon? = nil,
    destination: @escaping @autoclosure () -> Page
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.destination = destination
  }

  var body: Element {
    ActionListItem(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      isItemLink: true
    ) {
      App.navigate(to: destination())
    }
  }
}

// MARK: Swipeout

struct Swipeout {
  struct Action: Element, Sendable {
    let title: String
    var color: ThemeColor?
    let action: @MainActor () -> Void

    var body: Element {
      Link(title, classes: classList, action: action)
    }

    private var classList: [HTMLClass] {
      if let color {
        [.swipeoutClose, color.class]
      } else {
        [.swipeoutClose]
      }
    }
  }

  struct Group: Sendable {
    enum Edge {
      case leading, trailing
    }

    let edge: Edge
    let actions: [Action]
  }
}
extension Swipeout: EnvironmentKey {
  static let defaultValue: [Group] = []
}

@resultBuilder
struct SwipeoutBuilder {
  static func buildBlock(_ components: Swipeout.Action...) -> [Swipeout.Group] {
    [.init(edge: .trailing, actions: components)]
  }
  static func buildBlock(_ components: Swipeout.Group...) -> [Swipeout.Group] {
    components
  }
}

extension ListItemElement {
  func swipeActions(@SwipeoutBuilder actions: () -> [Swipeout.Group]) -> Element {
    self.environment(Swipeout.self, actions())
  }
}

extension HTMLClass {
  static let list: Self = "list"
  static let listDividers: Self = "list-dividers"
  static let listOutline: Self = "list-outline"
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
  static let swipeoutOverswipe: Self = "swipeout-overswipe"
}

// MARK: Popover

struct Popover: Element {
  let label: () -> [Element]
  let content: () -> [Element]
  let instance = "my-popover-" + UUID().uuidString.replacingOccurrences(of: "-", with: "")

  init(
    @ElementBuilder label: @escaping () -> [Element],
    @ElementBuilder content: @escaping () -> [Element]
  ) {
    self.label = label
    self.content = content
  }

  init(
    _ label: String,
    @ElementBuilder content: @escaping () -> [Element]
  ) {
    self.label = { [HTML(.span) { $1.innerText = .string(label) }] }
    self.content = content
  }

  var body: Element {
    HTML(.a, classes: .link, .popoverOpen) {
      $1.href = "#"
      $1.dataset.popover = .string("." + instance)
    } containing: {
      label()
      HTML(.div, classes: .popover, .class(instance)) {
        HTML(.div, class: .popoverInner, containing: content)
      }
      .environment(InsidePopover.self, true)
    }
  }
}
extension Popover {
  struct InsidePopover: EnvironmentKey {
    static let defaultValue = false
  }
}

extension HTMLClass {
  static let popover: Self = "popover"
  static let popoverOpen: Self = "popover-open"
  static let popoverClose: Self = "popover-close"
  static let popoverInner: Self = "popover-inner"
}