import JavaScriptKit
import SwiftNavigation

@MainActor
protocol EnvironmentKey {
  associatedtype Value: Sendable
  static var defaultValue: Value { get }
}

enum Environment {
  @TaskLocal fileprivate static var storage: [String: Sendable] = [:]
  @MainActor
  static subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
    get {
      return (storage[key.key] as? K.Value) ?? K.defaultValue
    }
  }
}

extension Element {
  func environment<K: EnvironmentKey>(_ key: K.Type, _ value: K.Value) -> Element {
    ElementEnvironmentWrapper(self, key: key, value: value)
  }
}
extension Page {
  func environment<K: EnvironmentKey>(_ key: K.Type, _ value: K.Value) -> Page {
    PageEnvironmentWrapper(self, key: key, value: value)
  }
}

@MainActor
protocol EnvironmentWrapper {
  func withEnvironment(_ perform: () -> Void)
}

extension EnvironmentKey {
  fileprivate static var key: String { String(describing: Self.self) }
}

private struct ElementEnvironmentWrapper<T: Element, K: EnvironmentKey>: Element {
  private let wrapped: T
  private let value: K.Value
  private let key: K.Type

  private var localStorage: [String: any Sendable] {
    var localStorage = Environment.storage
    localStorage[key.key] = value
    return localStorage
  }

  init(_ wrapped: T, key: K.Type, value: K.Value) {
    self.wrapped = wrapped
    self.key = key
    self.value = value
  }

  // Element conformance

  var body: Element {
    Environment.$storage.withValue(localStorage) { wrapped.body }
  }

  func render(parentNode: JSValue) -> JSObject {
    Environment.$storage.withValue(localStorage) { wrapped.render(parentNode: parentNode) }
  }
}

private struct PageEnvironmentWrapper<T: Page, K: EnvironmentKey>: EnvironmentWrapper, Page {
  private let wrapped: T
  private let value: K.Value
  private let key: K.Type

  private var localStorage: [String: any Sendable] {
    var localStorage = Environment.storage
    localStorage[key.key] = value
    return localStorage
  }

  init(_ wrapped: T, key: K.Type, value: K.Value) {
    self.wrapped = wrapped
    self.key = key
    self.value = value
  }

  func withEnvironment(_ perform: () -> Void) {
    if let subWrapped = wrapped as? EnvironmentWrapper {
      Environment.$storage.withValue(localStorage) {
        subWrapped.withEnvironment(perform)
      }
    } else {
      Environment.$storage.withValue(localStorage, operation: perform)
    }
  }

  // Page conformance

  var name: String {
    Environment.$storage.withValue(localStorage) { wrapped.name }
  }
  var controls: [Element] {
    Environment.$storage.withValue(localStorage) { wrapped.controls }
  }
  var content: [Element] {
    Environment.$storage.withValue(localStorage) { wrapped.content }
  }

  func observing() {
    Environment.$storage.withValue(localStorage) { wrapped.observing() }
  }
  func observables() -> Set<ObserveToken> {
    Environment.$storage.withValue(localStorage) { wrapped.observables() }
  }
  func willBeAdded() {
    Environment.$storage.withValue(localStorage) { wrapped.willBeAdded() }
  }
  func onAdded() {
    Environment.$storage.withValue(localStorage) { wrapped.onAdded() }
  }
  func willBeRemoved() {
    Environment.$storage.withValue(localStorage) { wrapped.willBeRemoved() }
  }
  func onRemoved() {
    Environment.$storage.withValue(localStorage) { wrapped.onRemoved() }
  }

  // Element conformance

  var body: Element {
    Environment.$storage.withValue(localStorage) { wrapped.body }
  }

  func render(parentNode: JSValue) -> JSObject {
    Environment.$storage.withValue(localStorage) { wrapped.render(parentNode: parentNode) }
  }
}