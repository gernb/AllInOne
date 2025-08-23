//
// Copyright © 2025 peter bohac. All rights reserved.
//

@preconcurrency import JavaScriptKit

/// Swift bridging code to commonly used global JavaScript / browser DOM entities.
public enum Global {
  /// The browser's timezone offset in hours.
  public static let tzOffset = -Date.new().jsValue.getTimezoneOffset().number!
  /// The JavaScript `URL.createObjectURL` static function.
  public static let createObjectURL = JSObject.global.URL.function!.createObjectURL.function!
  /// The JavaScript `FileReader` object.
  public static let FileReader = JSObject.global.FileReader.function!
  /// The JavaScript console used for logging.
  public static let console = JSObject.global.console

  /// The JavaScript `Date` object.
  static let Date = JSObject.global.Date.function!
}

// This is generally not a good idea, but JS in a browser is single-threaded.
extension JSValue: @retroactive @unchecked Sendable {}
extension JSPromise: @retroactive @unchecked Sendable {}
extension JSFunction: @retroactive @unchecked Sendable {}