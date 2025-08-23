//
// Copyright © 2025 peter bohac. All rights reserved.
//

@preconcurrency import JavaScriptKit

/// A type that can render itself as HTML.
@MainActor
protocol Element {
  /// (optional) A unique ID for this instance. Can be useful for obtaining the rendered node from the DOM.
  var id: HTMLId? { get }
  /// Describes how to render this instance into HTML.
  var body: Element { get }
  /// (optional) Renders this instance into an HTML node. The default implementation simply renders the `body` content.
  /// - Parameter message: The parent node of this instance in the DOM.
  func render(parentNode: JSValue) -> JSObject
}
extension Element {
  var id: HTMLId? { nil }
  func render(parentNode: JSValue) -> JSObject { body.render(parentNode: parentNode) }
}

/// Provides a DSL for simplifying the declaration of `Element` instances.
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

/// A type that can be used create `Element` IDs.
/// `String` conforms to this, but application-specific enums could also be made to conform to this.
protocol HTMLId {
  var id: String { get }
}
extension String: HTMLId {
  var id: String { self }
}

/// A type-safe way to reference common HTML tag values (like "div", "button", etc).
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
  /// Helper method to use an HTML tag that is not pre-defined below.
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

/// A type-safe way to reference HTML "class" values.
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
  /// Helper method to use a runtime-dynamic class value.
  static func `class`(_ rawValue: String) -> Self { .init(rawValue) }
}

/// Bridge type that allows for the creation of HTML at runtime.
struct HTML: Element {
  private static let doc = JSObject.global.document
  private static let emptyBuilder: Builder = { _, _ in }
  private static let emptyContents: Contents = {[]}

  /// A function that takes the instance's parent node and the instance as input
  /// and allows for customisation of the instance.
  typealias Builder = (_ parentNode: JSValue, _ node: JSValue) -> Void
  /// A function that generates `Element`s when invoked.
  typealias Contents = @MainActor () -> [Element]

  /// The HTML "tag" value.
  let tag: HTMLTag
  /// An optional HTML "id" for this instance.
  let id: HTMLId?
  /// The collection of HTML classes for this instance.
  let classList: [HTMLClass]
  /// The custom builder function to be invoked when this instance is rendered.
  let builder: Builder
  /// The custom contents function to be invoked when this instance is rendered.
  let contents: Contents

  /// Default (or primary) initialiser for this type.
  /// - Parameters:
  ///   - tag: The HTML tag for this instance.
  ///   - id: (optional) The HTML id for this instance.
  ///   - classList: (optional) The HTML classes for this instance.
  ///   - builder: A function that is invoked when this instance is rendered to allow for customisation of the rendered node.
  ///   - contents: A function that is invoked when this instance is rendered to allow for content (children) to be added to this node.
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

  /// Initialiser overload that allows for creating an instance with no builder or contents.
  /// - Parameters:
  ///   - tag: The HTML tag for this instance.
  ///   - id: (optional) The HTML id for this instance.
  ///   - classList: (optional) The HTML classes for this instance.
  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classList: [HTMLClass] = []
  ) {
    self.init(tag, id: id, classList: classList, builder: Self.emptyBuilder, containing: Self.emptyContents)
  }

  /// Initialiser overload that allows for creating an instance with a builder, but no contents.
  /// - Parameters:
  ///   - tag: The HTML tag for this instance.
  ///   - id: (optional) The HTML id for this instance.
  ///   - classList: (optional) The HTML classes for this instance.
  ///   - builder: A function that is invoked when this instance is rendered to allow for customisation of the rendered node.
  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classList: [HTMLClass] = [],
    builder: @escaping Builder
  ) {
    self.init(tag, id: id, classList: classList, builder: builder, containing: Self.emptyContents)
  }

  /// Initialiser overload that allows for creating an instance with contents, but no builder.
  /// - Parameters:
  ///   - tag: The HTML tag for this instance.
  ///   - id: (optional) The HTML id for this instance.
  ///   - classList: (optional) The HTML classes for this instance.
  ///   - contents: A function that is invoked when this instance is rendered to allow for content (children) to be added to this node.
  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classList: [HTMLClass] = [],
    @ElementBuilder containing contents: @escaping Contents
  ) {
    self.init(tag, id: id, classList: classList, builder: Self.emptyBuilder, containing: contents)
  }

  /// Initialiser overload that allows for the classlist to be provided as a variadic list instead of an array.
  /// - Parameters:
  ///   - tag: The HTML tag for this instance.
  ///   - id: (optional) The HTML id for this instance.
  ///   - classes: One or more HTML classes to add to this instance.
  ///   - builder: A function that is invoked when this instance is rendered to allow for customisation of the rendered node.
  ///   - contents: A function that is invoked when this instance is rendered to allow for content (children) to be added to this node.
  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classes: HTMLClass...,
    builder: @escaping Builder,
    @ElementBuilder containing contents: @escaping Contents
  ) {
    self.init(tag, id: id, classList: Array(classes), builder: builder, containing: contents)
  }

  /// Initialiser overload that allows for the classlist to be provided as a variadic list instead of an array and does not require a builder or contents.
  /// - Parameters:
  ///   - tag: The HTML tag for this instance.
  ///   - id: (optional) The HTML id for this instance.
  ///   - classes: One or more HTML classes to add to this instance.
  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classes: HTMLClass...
  ) {
    self.init(tag, id: id, classList: Array(classes), builder: Self.emptyBuilder, containing: Self.emptyContents)
  }

  /// Initialiser overload that allows for the classlist to be provided as a variadic list instead of an array and does not require contents to be provided.
  /// - Parameters:
  ///   - tag: The HTML tag for this instance.
  ///   - id: (optional) The HTML id for this instance.
  ///   - classes: One or more HTML classes to add to this instance.
  ///   - builder: A function that is invoked when this instance is rendered to allow for customisation of the rendered node.
  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classes: HTMLClass...,
    builder: @escaping Builder
  ) {
    self.init(tag, id: id, classList: Array(classes), builder: builder, containing: Self.emptyContents)
  }

  /// Initialiser overload that allows for the classlist to be provided as a variadic list instead of an array and does not require a builder to be provided.
  /// - Parameters:
  ///   - tag: The HTML tag for this instance.
  ///   - id: (optional) The HTML id for this instance.
  ///   - classes: One or more HTML classes to add to this instance.
  ///   - contents: A function that is invoked when this instance is rendered to allow for content (children) to be added to this node.
  init(
    _ tag: HTMLTag,
    id: HTMLId? = nil,
    classes: HTMLClass...,
    @ElementBuilder containing contents: @escaping Contents
  ) {
    self.init(tag, id: id, classList: Array(classes), builder: Self.emptyBuilder, containing: contents)
  }

  /// The `HTML` type does not define a body; it can only be rendered by the custom `render(parentNode:)` function.
  var body: Element {
    fatalError("Only render() should be called on `HTML`")
  }

  /// Creates a new node in the DOM and configures it with the instance details.
  /// This function does not add the new node to the parent.
  /// - Parameter parentNode: The DOM node this new instance is intended to be added to.
  /// - Returns: The newly created node; it is not added to the parent node.
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
  /// Modifies the instance to add additional HTML classes to it when rendered.
  /// - Parameter classes: The additional HTML classes to be added.
  /// - Returns: The modified instance.
  func addingClasses(_ classes: HTMLClass...) -> Element {
    addingClasses(Array(classes))
  }
  /// Modifies the instance to add additional HTML classes to it when rendered.
  /// - Parameter classes: The additional HTML classes to be added.
  /// - Returns: The modified instance.
  func addingClasses(_ classes: [HTMLClass]) -> Element {
    ElementModifier(self) {
      for c in classes {
        _ = $0.classList.add(c.rawValue)
      }
    }
  }
}

/// A wrapper around an Element that contains the modifications to be made to the
/// instance when it is rendered.
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