@preconcurrency import JavaScriptKit

@MainActor
protocol Element {
  var body: Element { get }
  func render() -> JSObject
}
extension Element {
  func render() -> JSObject { body.render() }
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

  let tag: HTMLTag
  let classList: [HTMLClass]
  let builder: (JSValue) -> Void
  let contents: () -> [Element]

  init(
    _ tag: HTMLTag,
    classList: [HTMLClass],
    builder: @escaping (JSValue) -> Void,
    @ElementBuilder containing contents: @escaping () -> [Element]
  ) {
    self.tag = tag
    self.classList = classList
    self.builder = builder
    self.contents = contents
  }

  init(
    _ tag: HTMLTag,
    classList: [HTMLClass],
    builder: @escaping (JSValue) -> Void
  ) {
    self.init(tag, classList: classList, builder: builder, containing: Self.empty)
  }

  init(
    _ tag: HTMLTag,
    classes: HTMLClass...
  ) {
    self.init(tag, classList: Array(classes), builder: { _ in }, containing: Self.empty)
  }

  init(
    _ tag: HTMLTag,
    classes: HTMLClass...,
    builder: @escaping (JSValue) -> Void,
    @ElementBuilder containing contents: @escaping () -> [Element]
  ) {
    self.init(tag, classList: Array(classes), builder: builder, containing: contents)
  }

  init(
    _ tag: HTMLTag,
    classes: HTMLClass...,
    @ElementBuilder containing contents: @escaping () -> [Element]
  ) {
    self.init(tag, classList: Array(classes), builder: { _ in }, containing: contents)
  }

  init(
    _ tag: HTMLTag,
    class: HTMLClass? = nil,
    builder: @escaping (JSValue) -> Void,
    @ElementBuilder containing contents: @escaping () -> [Element]
  ) {
    self.init(tag, classList: `class`.map {[$0]} ?? [], builder: builder, containing: contents)
  }

  init(
    _ tag: HTMLTag,
    class: HTMLClass? = nil,
    builder: @escaping (JSValue) -> Void
  ) {
    self.init(tag, classList: `class`.map { [$0] } ?? [], builder: builder, containing: Self.empty)
  }

  init(
    _ tag: HTMLTag,
    class: HTMLClass? = nil,
    @ElementBuilder containing contents: @escaping () -> [Element] = { [] }
  ) {
    self.init(tag, classList: `class`.map { [$0] } ?? [], builder: { _ in }, containing: contents)
  }

  var body: Element {
    fatalError("Only render() should be called on `HTML`")
  }

  func render() -> JSObject {
    let node = Self.doc.createElement(tag.rawValue)
    for c in classList {
      _ = node.classList.add(c.rawValue)
    }
    builder(node)
    for child in contents() {
      _ = node.appendChild(child.render())
    }
    return node.object!
  }
}

extension Never: Element {
  var body: Element { fatalError() }
}