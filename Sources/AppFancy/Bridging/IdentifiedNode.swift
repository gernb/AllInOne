//
// Copyright © 2025 peter bohac. All rights reserved.
//

import Foundation
import JavaScriptKit

/// A DOM node (element) that is uniquely identified so that it can be
/// looked up and accessed bu code that runs after instantiation.
/// This is basically a way to get a reference to the actual instance
/// from any code path; (thus decoupling rendering from monitoring logic).
@dynamicMemberLookup
struct IdentifiedNode: ExpressibleByStringLiteral, HTMLId {
  private static let doc = JSObject.global.document
  /// The node's unique ID
  let id: String
  /// The node that is resolved when accessed
  var node: JSValue { Self.doc.getElementById(id) }

  /// Creates an instance with a random, unique ID.
  init() {
    self.id = UUID().uuidString
  }
  /// Creates an instance with the specified ID.
  init(_ id: String) {
    self.id = id
  }
  /// Creates an instance with the specified ID from a string literal.
  init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }

  // Allows for calling functions on the node
  subscript(dynamicMember name: String) -> ((ConvertibleToJSValue...) -> JSValue) {
      node[dynamicMember: name]
  }

  // Allows for reading and writing properties on the node
  subscript(dynamicMember name: String) -> JSValue {
    get { node[dynamicMember: name] }
    nonmutating set { node[dynamicMember: name] = newValue }
  }

  /// Helper method that adds a new element to this node as a child.
  @MainActor
  func add(_ element: Element) {
    _ = node.appendChild(element.render(parentNode: node))
  }

  /// Helper method that removes all child nodes.
  func clear() {
    _ = node.replaceChildren()
  }
}