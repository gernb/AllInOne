@preconcurrency import JavaScriptKit

public enum Global {
  public static let tzOffset = -Date.new().jsValue.getTimezoneOffset().number!

  static let Date = JSObject.global.Date.function!
}

extension JSValue: @retroactive @unchecked Sendable {}
extension JSPromise: @retroactive @unchecked Sendable {}
extension JSFunction: @retroactive @unchecked Sendable {}