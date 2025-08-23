//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Card widget to Swift.
/// https://framework7.io/docs/cards
struct Card: Element {
  @ElementBuilder let content: HTML.Contents

  var body: Element {
    HTML(.div, classes: .card, .cardContentPadding, .cardRaised, .cardOutline) {
      HTML(.div, classes: .cardContent, containing: content)
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
