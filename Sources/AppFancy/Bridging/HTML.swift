@preconcurrency import JavaScriptKit

@MainActor
protocol Element {
  var id: HTMLId? { get }
  var body: Element { get }
  func render(parentNode: JSValue) -> JSObject
}
extension Element {
  var id: HTMLId? { nil }
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
  static func buildArray(_ components: [[Element]]) -> [Element] {
    components.flatMap { $0 }
  }
  static func buildEither(first components: [Element]) -> [Element] {
    components
  }
  static func buildEither(second components: [Element]) -> [Element] {
    components
  }
}

protocol HTMLId {
  var id: String { get }
}
extension String: HTMLId {
  var id: String { self }
}

struct HTMLTag: ExpressibleByStringLiteral, RawRepresentable {
  let rawValue: String
  init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
  init?(rawValue: String) {
    self.init(rawValue)
  }
}
extension HTMLTag {
  static func tag(_ rawValue: String) -> Self { .init(rawValue) }
  static let div: Self = "div"
  static let span: Self = "span"
  static let p: Self = "p"
  static let br: Self = "br"
  static let a: Self = "a"
  static let i: Self = "i"
  static let button: Self = "button"
  static let ul: Self = "ul"
  static let li: Self = "li"
}

struct HTMLClass: ExpressibleByStringLiteral, Hashable, RawRepresentable {
  let rawValue: String
  init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
  init?(rawValue: String) {
    self.init(rawValue)
  }
}
extension HTMLClass {
  static func `class`(_ rawValue: String) -> Self { .init(rawValue) }
}

struct HTML: Element {
  private static let doc = JSObject.global.document
  private static let emptyBuilder: Builder = { _, _ in }
  private static let emptyContents: Contents = {[]}

  typealias Builder = (_ parentNode: JSValue, _ node: JSValue) -> Void
  typealias Contents = @MainActor () -> [Element]

  let tag: HTMLTag
  let id: HTMLId?
  let classList: [HTMLClass]
  let builder: Builder
  let contents: Contents

  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classList: [HTMLClass] = [],
    builder: @escaping Builder,
    @ElementBuilder containing contents: @escaping Contents
  ) {
    self.tag = tag
    self.id = id
    self.classList = classList
    self.builder = builder
    self.contents = contents
  }

  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classList: [HTMLClass] = []
  ) {
    self.init(tag, id: id, classList: classList, builder: Self.emptyBuilder, containing: Self.emptyContents)
  }

  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classList: [HTMLClass] = [],
    builder: @escaping Builder
  ) {
    self.init(tag, id: id, classList: classList, builder: builder, containing: Self.emptyContents)
  }

  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classList: [HTMLClass] = [],
    @ElementBuilder containing contents: @escaping Contents
  ) {
    self.init(tag, id: id, classList: classList, builder: Self.emptyBuilder, containing: contents)
  }

  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classes: HTMLClass...,
    builder: @escaping Builder,
    @ElementBuilder containing contents: @escaping Contents
  ) {
    self.init(tag, id: id, classList: Array(classes), builder: builder, containing: contents)
  }

  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classes: HTMLClass...
  ) {
    self.init(tag, id: id, classList: Array(classes), builder: Self.emptyBuilder, containing: Self.emptyContents)
  }

  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classes: HTMLClass...,
    builder: @escaping Builder
  ) {
    self.init(tag, id: id, classList: Array(classes), builder: builder, containing: Self.emptyContents)
  }

  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classes: HTMLClass...,
    @ElementBuilder containing contents: @escaping Contents
  ) {
    self.init(tag, id: id, classList: Array(classes), builder: Self.emptyBuilder, containing: contents)
  }

  var body: Element {
    fatalError("Only render() should be called on `HTML`")
  }

  func render(parentNode: JSValue) -> JSObject {
    let node = Self.doc.createElement(tag.rawValue)
    if let id = id?.id {
      node.id = .string(id)
    }
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

extension Element {
  func addingClasses(_ classes: HTMLClass...) -> Element {
    addingClasses(Array(classes))
  }
  func addingClasses(_ classes: [HTMLClass]) -> Element {
    ElementModifier(self) {
      for c in classes {
        _ = $0.classList.add(c.rawValue)
      }
    }
  }
}

private struct ElementModifier<T: Element>: Element {
  private let wrapped: T
  private let modify: (_ node: JSObject) -> Void

  var body: Element {
    self
  }

  init(_ wrapped: T, with modify: @escaping (JSObject) -> Void) {
    self.wrapped = wrapped
    self.modify = modify
  }

  func render(parentNode: JSValue) -> JSObject {
    let node = wrapped.render(parentNode: parentNode)
    modify(node)
    return node
  }
}

extension Never: Element {
  var body: Element { fatalError() }
}