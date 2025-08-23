//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

extension Element {
  /// Modifies the containing frame to control the maximum width and height.
  /// - Parameters:
  ///   - maxWidth: (optional) The maximum width in pixels.
  ///   - maxHeight: (optional) The maximum height in pixels.
  /// - Returns: 
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

// MARK: Colours

/// Wrapper that bridges the Framework7 theme colours to Swift.
/// https://framework7.io/docs/color-themes
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