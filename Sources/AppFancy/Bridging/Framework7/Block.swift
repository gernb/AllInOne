import JavaScriptKit

struct Block: Element {
  let styles: [Style]
  let content: HTML.Contents

  init(styles: [Style], @ElementBuilder content: @escaping HTML.Contents) {
    self.styles = styles
    self.content = content
  }

  init(style: Style..., @ElementBuilder content: @escaping HTML.Contents) {
    self.init(styles: style, content: content)
  }

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
