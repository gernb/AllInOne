//
// Copyright © 2025 peter bohac. All rights reserved.
//

import AppShared
import JavaScriptKit

/// A View that renders a single list item (file or folder) and handles events on that item.
struct ListItem: View {
  /// The text label; file or folder name
  private let label: String
  /// The image icon
  private let image: String
  /// Callback when the item is tapped / clicked.
  private let itemTapped: () -> Void
  /// Callback when the item's "trash" button is tapped / clicked.
  private let trashTapped: () -> Void

  /// Creates a new list item
  /// - Parameters:
  ///   - label: The item's text label (file or folder name).
  ///   - isFolder: Whether the item represents a folder; default is `false`.
  ///   - itemTapped: Callback when the item is tapped / clicked; default is no-op.
  ///   - trashTapped: Callback when the item's "trash" button is tapped / clicked; default is no-op.
  init(
    _ label: String,
    isFolder: Bool = false,
    itemTapped: @escaping () -> Void = {},
    trashTapped: @escaping () -> Void = {}
  ) {
    self.label = label
    self.image = DOM.locationPath + (isFolder ? "/folder.png" : "/file.png")
    self.itemTapped = itemTapped
    self.trashTapped = trashTapped
  }

  func render() -> JSValue {
    DOM.create("div") { body in
      body.style = "display: flex; margin: 10px 0; max-width: 350px;"

      DOM.addNew("div", to: body) { div in
        div.style = "display: flex; flex-grow: 1; align-items: center;"
        div.onClick(itemTapped)
        DOM.addNew("img", to: div) {
          $0.src = .string(image)
          $0.height = 40
        }
        DOM.addNew("span", to: div) {
          $0.style = "margin: 0 10px;"
          $0.innerText = .string(label)
        }
      }

      DOM.addNew("img", to: body) {
        $0.src = .string(DOM.locationPath + "/trash-can.png")
        $0.height = 40
        $0.onClick(trashTapped)
      }
    }
  }

  func onAdded() {
    print("[ListItem] '\(label)' added")
  }

  func onRemoved() {
    print("[ListItem] '\(label)' removed")
  }
}