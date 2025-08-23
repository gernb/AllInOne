//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Button control to Swift.
/// https://framework7.io/docs/button
struct Button: Element {
  let label: HTML.Contents
  let action: () -> Void

  /// Creates a new `Button` with a custom action and UI label.
  /// - Parameters:
  ///   - action: The callback to be invoked when the user actions on (taps/clicks) the button.
  ///   - label: The custom UI to show for this button.
  init(
    action: @escaping () -> Void,
    @ElementBuilder label: @escaping HTML.Contents
  ) {
    self.label = label
    self.action = action
  }

  /// Creates a new `Button` with a custom action and a text label.
  /// - Parameters:
  ///   - label: The text string to show for this button.
  ///   - action: The callback to be invoked when the user actions on (taps/clicks) the button.
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
  /// Button shapes that can be used to style a button.
  enum Shape {
    case rect, round
  }
  /// Button fills that cen be used to style a button.
  enum Fill {
    case none, tonal, solid, outline
  }
  /// Button sizes that can be used to style a button.
  enum Size {
    case small, normal, large
  }
  /// Buttons can be "raised" or not.
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
  /// Changes the style used to visually display buttons inside the enclosing `Element`.
  /// - Parameters:
  ///   - fill: Modifies the button fill.
  ///   - raised: Modifies whether the button is raised or not.
  ///   - shape: Modifies the button shape.
  ///   - size: Modifies the button size.
  /// - Returns: The modified `Element`.
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