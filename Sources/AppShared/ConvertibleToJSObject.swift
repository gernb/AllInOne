import JavaScriptKit

public protocol ConvertibleToJSObject {
  func jsObject() -> JSObject
}
extension Dictionary: ConvertibleToJSObject where Key == String {
  public func jsObject() -> JSObject {
    let result = JSObject()
    for (key, value) in self {
      switch value {
      case let value as String:
        result[key] = JSValue(stringLiteral: value)
      case let value as Int32:
        result[key] = JSValue(integerLiteral: value)
      case let value as Double:
        result[key] = JSValue(floatLiteral: value)
      case let value as Bool:
        result[key] = .boolean(value)
      case let value as JSObject:
        result[key] = .object(value)
      case let value as ConvertibleToJSObject:
        result[key] = value.jsObject().jsValue
      case let value as JSValue:
        result[key] = value
      default:
        print(key, value)
        fatalError()
      }
    }
    return result
  }
}