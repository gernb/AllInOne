import JavaScriptKit

@dynamicMemberLookup
struct IdentifiedNode: ExpressibleByStringLiteral, HTMLId {
  private static let doc = JSObject.global.document
  let id: String
  var node: JSValue { Self.doc.getElementById(id) }

  init(_ id: String) {
    self.id = id
  }
  init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }

  subscript(dynamicMember name: String) -> JSValue {
    get { node[dynamicMember: name] }
    nonmutating set { node[dynamicMember: name] = newValue }
  }
}