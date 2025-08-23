//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Block widget to Swift.
/// A block is a UI element that visually calls out some section by indenting, outlining, etc.
/// https://framework7.io/docs/block
struct Block: Element {
  let styles: [Style]
  let content: HTML.Contents

  /// Creates a new `Block` with the provides styles and content.
  /// - Parameters:
  ///   - styles: The array of styles that describe how this block should be displayed.
  ///   - content: The content of this instance.
  init(styles: [Style], @ElementBuilder content: @escaping HTML.Contents) {
    self.styles = styles
    self.content = content
  }

  /// Creates a new `Block` with the provides styles and content.
  /// - Parameters:
  ///   - style: The style or styles that describe how this block should be displayed.
  ///   - content: The content of this instance.
  init(style: Style..., @ElementBuilder content: @escaping HTML.Contents) {
    self.init(styles: style, content: content)
  }

  /// Creates a new `Block` with no additional styling.
  /// - Parameter content: The content of this instance.
  init(@ElementBuilder content: @escaping HTML.Contents) {
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
  /// The visual styles for a `Block` widget.
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

/// Wrapper that bridges the Framework7 BlockFooter widget to Swift.
/// https://framework7.io/docs/block
struct BlockFooter: Element {
  @ElementBuilder var content: HTML.Contents
  var body: Element {
    HTML(.div, classes: .blockFooter, containing: content)
  }
}

extension HTMLClass {
  static let block: Self = "block"
  static let blockStrong: Self = "block-strong"
  static let blockOutline: Self = "block-outline"
  static let inset: Self = "inset"
  static let blockFooter: Self = "block-footer"
}
