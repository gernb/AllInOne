@preconcurrency import JavaScriptKit

@MainActor
protocol Element {
  var body: Element { get }
  func render(parentNode: JSValue) -> JSObject
}
extension Element {
  func render(parentNode: JSValue) -> JSObject { body.render(parentNode: parentNode) }
}

@resultBuilder
struct ElementBuilder {
  static func buildBlock(_ components: Element...) -> [Element] {
    components
  }
  static func buildBlock(_ components: [Element]...) -> [Element] {
    components.flatMap { $0 }
  }
  static func buildOptional(_ components: [Element]?) -> [Element] {
    components ?? []
  }
  static func buildExpression(_ expression: Element) -> [Element] {
    [expression]
  }
  static func buildExpression(_ expression: [Element]) -> [Element] {
    expression
  }
}

struct HTMLTag: ExpressibleByStringLiteral, RawRepresentable {
  let rawValue: String
  init(stringLiteral value: StringLiteralType) {
    self.rawValue = value
  }
  init?(rawValue: String) {
    self.rawValue = rawValue
  }
}
extension HTMLTag {
  static let div: Self = "div"
  static let span: Self = "span"
  static let p: Self = "p"
  static let br: Self = "br"
  static let a: Self = "a"
  static let i: Self = "i"
  static let button: Self = "button"
}

struct HTMLClass: ExpressibleByStringLiteral, Hashable, RawRepresentable {
  let rawValue: String
  init(stringLiteral value: StringLiteralType) {
    self.rawValue = value
  }
  init?(rawValue: String) {
    self.rawValue = rawValue
  }
}

struct HTML: Element {
  private static let doc = JSObject.global.document
  private static let empty: @Sendable () -> [Element] = {[]}

  typealias Builder = (_ parentNode: JSValue, _ node: JSValue) -> Void

  let tag: HTMLTag
  let classList: [HTMLClass]
  let builder: Builder
  let contents: () -> [Element]

  init(
    _ tag: HTMLTag,
    classList: [HTMLClass],
    builder: @escaping Builder,
    @ElementBuilder containing contents: @escaping () -> [Element]
  ) {
    self.tag = tag
    self.classList = classList
    self.builder = builder
    self.contents = contents
  }

  init(_ tag: HTMLTag) {
    self.init(tag, classList: [], builder: { _, _ in }, containing: Self.empty)
  }

  init(_ tag: HTMLTag, builder: @escaping Builder) {
    self.init(tag, classList: [], builder: builder, containing: Self.empty)
  }

  init(
    _ tag: HTMLTag,
    classList: [HTMLClass],
    builder: @escaping Builder
  ) {
    self.init(tag, classList: classList, builder: builder, containing: Self.empty)
  }

  init(
    _ tag: HTMLTag,
    classes: HTMLClass...
  ) {
    self.init(tag, classList: Array(classes), builder: { _, _ in }, containing: Self.empty)
  }

  init(
    _ tag: HTMLTag,
    classes: HTMLClass...,
    builder: @escaping Builder,
    @ElementBuilder containing contents: @escaping () -> [Element]
  ) {
    self.init(tag, classList: Array(classes), builder: builder, containing: contents)
  }

  init(
    _ tag: HTMLTag,
    classes: HTMLClass...,
    @ElementBuilder containing contents: @escaping () -> [Element]
  ) {
    self.init(tag, classList: Array(classes), builder: { _, _ in }, containing: contents)
  }

  init(
    _ tag: HTMLTag,
    class: HTMLClass,
    builder: @escaping Builder,
    @ElementBuilder containing contents: @escaping () -> [Element]
  ) {
    self.init(tag, classList: [`class`], builder: builder, containing: contents)
  }

  init(
    _ tag: HTMLTag,
    class: HTMLClass,
    builder: @escaping Builder
  ) {
    self.init(tag, classList: [`class`], builder: builder, containing: Self.empty)
  }

  init(
    _ tag: HTMLTag,
    class: HTMLClass,
    @ElementBuilder containing contents: @escaping () -> [Element] = { [] }
  ) {
    self.init(tag, classList: [`class`], builder: { _, _ in }, containing: contents)
  }

  var body: Element {
    fatalError("Only render() should be called on `HTML`")
  }

  func render(parentNode: JSValue) -> JSObject {
    let node = Self.doc.createElement(tag.rawValue)
    for c in classList {
      _ = node.classList.add(c.rawValue)
    }
    builder(parentNode, node)
    for child in contents() {
      _ = node.appendChild(child.render(parentNode: node))
    }
    return node.object!
  }
}

extension Never: Element {
  var body: Element { fatalError() }
}