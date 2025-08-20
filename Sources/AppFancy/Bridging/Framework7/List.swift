import JavaScriptKit

// MARK: List

struct List: Element {
  let id: HTMLId?
  let content: () -> [Element]

  init(id: HTMLId? = nil, @ElementBuilder content: @escaping () -> [Element] = { [] }) {
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

// MARK: List Elements

protocol ListItemElement: Element {}

struct ListItem: ListItemElement {
  let id: HTMLId?
  let title: String
  let trailingAccessory: (() -> [Element])?
  let icon: Icon?

  init(id: HTMLId? = nil, title: String, icon: F7Icon? = nil) {
    self.id = id
    self.title = title
    self.trailingAccessory = nil
    self.icon = icon.map { Icon($0) }
  }

  init(
    id: HTMLId? = nil,
    title: String,
    icon: F7Icon? = nil,
    @ElementBuilder trailingAccessory: @escaping () -> [Element]
  ) {
    self.id = id
    self.title = title
    self.trailingAccessory = trailingAccessory
    self.icon = icon.map { Icon($0) }
  }

  var body: Element {
    HTML(.li, id: id, classList: hasSwipeOut ? [.swipeout] : []) {
      HTML(.div, classList: hasSwipeOut ? [.itemContent, .swipeoutContent] : [.itemContent]) {
        Self.content(title: title, icon: icon, trailingAccessory: trailingAccessory)
      }
    }
  }

  private var hasSwipeOut: Bool { Environment[Swipeout.self].isEmpty == false }

  fileprivate static func content(title: String, icon: Icon?, trailingAccessory: (() -> [Element])?) -> [Element] {
    let media = icon.map { icon in
      HTML(.div, class: .itemMedia) {
        icon
      }
    }
    let inner = HTML(.div, class: .itemInner) {
      HTML(.div, class: .itemTitle) { $1.innerText = .string(title) }
      if let trailingAccessory {
        HTML(.div, class: .itemAfter, containing: trailingAccessory)
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
  let icon: Icon?
  let trailingAccessory: (() -> [Element])?
  let action: () -> Void

  init(
    id: HTMLId? = nil,
    title: String,
    icon: F7Icon? = nil,
    action: @escaping () -> Void
  ) {
    self.id = id
    self.title = title
    self.icon = icon.map { Icon($0) }
    self.trailingAccessory = nil
    self.action = action
  }

  init(
    id: HTMLId? = nil,
    title: String,
    icon: F7Icon? = nil,
    action: @escaping () -> Void,
    @ElementBuilder trailingAccessory: @escaping () -> [Element]
  ) {
    self.id = id
    self.title = title
    self.icon = icon.map { Icon($0) }
    self.action = action
    self.trailingAccessory = trailingAccessory
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
              // TODO: find a better solution to this problem
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
        ListItem.content(title: title, icon: icon, trailingAccessory: trailingAccessory)
      }
    }
  }

  private var classList: [HTMLClass] {
    var list = [HTMLClass.itemContent]
    if hasSwipeOut {
      list.append(.swipeoutContent)
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
    let view = Environment[View.self]
    return ActionListItem(
      id: id,
      title: title,
      icon: icon
    ) {
      view?.navigate(to: destination())
    } trailingAccessory: {
      Icon(.chevronRight)
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
      Link(classes: linkClassList, action: action) {
        HTML(.div, classList: labelClassList) {
          $1.innerText = .string(title)
        }
      }
    }

    private var linkClassList: [HTMLClass] {
      if let color {
        [.swipeoutClose, color.class]
      } else {
        [.swipeoutClose]
      }
    }

    private var labelClassList: [HTMLClass] {
      if color == nil {
        []
      } else {
        [.class("text-color-white")]
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