import JavaScriptKit

protocol EnvironmentKey {
  associatedtype Value: Sendable
  static var defaultValue: Value { get }
}

enum Environment {
  @TaskLocal fileprivate static var storage: [String: Sendable] = [:]
  static subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
    get {
      return (storage[key.key] as? K.Value) ?? K.defaultValue
    }
  }
}

extension Element {
  func environment<K: EnvironmentKey>(_ key: K.Type, _ value: K.Value) -> Element {
    EnvironmentWrapper(self, key: key, value: value)
  }
}

extension EnvironmentKey {
  fileprivate static var key: String { String(describing: Self.self) }
}

private struct EnvironmentWrapper<T: Element, K: EnvironmentKey>: Element {
  private let wrapped: T
  private let value: K.Value
  private let key: K.Type

  var body: Element {
    var localStorage = Environment.storage
    localStorage[key.key] = value
    return Environment.$storage.withValue(localStorage) { wrapped.body }
  }

  init(_ wrapped: T, key: K.Type, value: K.Value) {
    self.wrapped = wrapped
    self.key = key
    self.value = value
  }

  func render() -> JSObject {
    var localStorage = Environment.storage
    localStorage[key.key] = value
    return Environment.$storage.withValue(localStorage) { wrapped.render() }
  }
}