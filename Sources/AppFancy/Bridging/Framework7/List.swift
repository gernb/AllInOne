//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

// MARK: List

/// Wrapper that bridges the Framework7 List widget to Swift.
/// https://framework7.io/docs/list-view
struct List: Element {
  let id: HTMLId?
  let content: HTML.Contents

  /// Creates a new `List` instance.
  /// - Parameters:
  ///   - id: (optional) The unique ID for this instance.
  ///   - content: (optional) Initial content for this instance.
  init(id: HTMLId? = nil, @ElementBuilder content: @escaping HTML.Contents = { [] }) {
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
  /// List styles that can be used to modify the display of a List.
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
  /// Changes the style used to visually display lists inside the enclosing `Element`.
  /// - Parameter style: The new list style to use.
  /// - Returns: The modified `Element`.
  func listStyle(_ style: List.Style?) -> Element {
    self.environment(List.Style.self, style)
  }
}

// MARK: List Elements

/// Tags a type as being an item that can be displayed in a list.
protocol ListItemElement: Element {}

/// A list item that can display a title, icon, and trailing accessory view.
struct ListItem: ListItemElement {
  let id: HTMLId?
  let title: String
  let trailingAccessory: HTML.Contents?
  let icon: Icon?

  /// Creates a new `ListItem` instance.
  /// - Parameters:
  ///   - id: (optional) The unique ID for this instance.
  ///   - title: The text for the "title" slot in the UI.
  ///   - icon: An optional icon to display next to the title.
  init(id: HTMLId? = nil, title: String, icon: F7Icon? = nil) {
    self.id = id
    self.title = title
    self.trailingAccessory = nil
    self.icon = icon.map { Icon($0) }
  }

  /// Creates a new `ListItem` instance with a trailing accessory view.
  /// - Parameters:
  ///   - id: (optional) The unique ID for this instance.
  ///   - title: The text for the "title" slot in the UI.
  ///   - icon: An optional icon to display next to the title.
  ///   - trailingAccessory: The custom UI to display in the trailing accessory "slot".
  init(
    id: HTMLId? = nil,
    title: String,
    icon: F7Icon? = nil,
    @ElementBuilder trailingAccessory: @escaping HTML.Contents
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

  fileprivate static func content(title: String, icon: Icon?, trailingAccessory: HTML.Contents?) -> [Element] {
    let media = icon.map { icon in
      HTML(.div, classes: .itemMedia) {
        icon
      }
    }
    let inner = HTML(.div, classes: .itemInner) {
      HTML(.div, classes: .itemTitle) { $1.innerText = .string(title) }
      if let trailingAccessory {
        HTML(.div, classes: .itemAfter, containing: trailingAccessory)
      }
    }
    let leadingSwipeout = Environment[Swipeout.self]
      .first { $0.edge == .leading && $0.actions.isEmpty == false }
      .map { group in
        HTML(.div, classes: .swipeoutActionsLeft) {
          group.actions[0].addingClasses(.swipeoutOverswipe)
          Array(group.actions.dropFirst())
        }
      }
    let trailingSwipeout = Environment[Swipeout.self]
      .first { $0.edge == .trailing && $0.actions.isEmpty == false }
      .map { group in
        HTML(.div, classes: .swipeoutActionsRight) {
          Array(group.actions.dropLast())
          group.actions.last!.addingClasses(.swipeoutOverswipe)
        }
      }
    return [media, inner, leadingSwipeout, trailingSwipeout].compactMap { $0 }
  }
}

/// An actionable list item that can display a title, icon, and trailing accessory view.
/// This list item supports the user tapping/clicking it.
struct ActionListItem: ListItemElement {
  let id: HTMLId?
  let title: String
  let icon: Icon?
  let trailingAccessory: HTML.Contents?
  let action: () -> Void

  /// Creates a new `ActionListItem` instance.
  /// - Parameters:
  ///   - id: (optional) The unique ID for this instance.
  ///   - title: The text for the "title" slot in the UI.
  ///   - icon: An optional icon to display next to the title.
  ///   - action: Callback that is invoked when the user taps/clicks on the item.
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

  /// Creates a new `ActionListItem` instance with a trailing accessory view.
  /// - Parameters:
  ///   - id: (optional) The unique ID for this instance.
  ///   - title: The text for the "title" slot in the UI.
  ///   - icon: An optional icon to display next to the title.
  ///   - action: Callback that is invoked when the user taps/clicks on the item.
  ///   - trailingAccessory: The custom UI to display in the trailing accessory "slot".
  init(
    id: HTMLId? = nil,
    title: String,
    icon: F7Icon? = nil,
    action: @escaping () -> Void,
    @ElementBuilder trailingAccessory: @escaping HTML.Contents
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
      // Framework7 seems to invoke the item tap action when the user swipes or taps on the swipe action button.
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

/// A list item that can display a title, icon, and trailing accessory view.
/// This list item supports the user tapping/clicking it and performs a navigate to the destination when tapped.
struct NavigationListItem: ListItemElement {
  let id: HTMLId?
  let title: String
  let icon: F7Icon?
  let destination: () -> Page

  /// Creates a new `NavigationListItem` instance.
  /// - Parameters:
  ///   - id: (optional) The unique ID for this instance.
  ///   - title: The text for the "title" slot in the UI.
  ///   - icon: An optional icon to display next to the title.
  ///   - destination: The `Page` to navigate to when tapped.
  init(
    id: HTMLId? = nil,
    title: String,
    icon: F7Icon? = nil,
    destination: @escaping @autoclosure () -> Page
  ) {
    self.id = id
    self.title = title
    self.icon = icon
    self.destination = destination
  }

  var body: Element {
    let view = View.current
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

/// Wrapper that bridges the Framework7 Swipeout control to Swift.
/// https://framework7.io/docs/swipeout
struct Swipeout {
  /// A single swipeout action item in a swipeout group.
  struct Action: Element, Sendable {
    /// The text label for this item.
    let title: String
    /// An optional colour for this item.
    var color: ThemeColor?
    /// The callback to invoke when this item is tapped/clicked.
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

  /// A group of swipeout actions that are displayed together.
  struct Group: Sendable {
    /// The list item edge where this group is displayed.
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

/// Provides a DSL for simplifying the declaration of `Swipeout` instances.
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
  /// Adds a group of "swipeout" actions to a list item.
  /// - Parameter actions: The action group to add.
  /// - Returns: The modified list item.
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