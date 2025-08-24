//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit
import SwiftNavigation

/// A type that can be stored the global environment.
@MainActor
protocol EnvironmentKey {
  /// The type must be `Sendable`
  associatedtype Value: Sendable
  /// The global Environment must have a default value for this type
  static var defaultValue: Value { get }
}

/// The global environment. Similar in concept to the SwiftUI Environment.
enum Environment {
  @TaskLocal fileprivate static var storage: [String: Sendable] = [:]
  /// In this simplified Environment, values are referenced by their registered type.
  @MainActor
  static subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
    get {
      return (storage[key.key] as? K.Value) ?? K.defaultValue
    }
  }
}

extension Element {
  /// Modifies the Environment for all sub-elements with a new value.
  /// - Parameters:
  ///   - key: The Environment value to override.
  ///   - value: The new value to use.
  /// - Returns: The modified Element.
  func environment<K: EnvironmentKey>(_ key: K.Type, _ value: K.Value) -> Element {
    ElementEnvironmentWrapper(self, key: key, value: value)
  }
}
extension Page {
  /// Modifies the Environment for all sub-pages and sub-elements with a new value.
  /// - Parameters:
  ///   - key: The Environment value to override.
  ///   - value: The new value to use.
  /// - Returns: The modified Page.
  func environment<K: EnvironmentKey>(_ key: K.Type, _ value: K.Value) -> Page {
    PageEnvironmentWrapper(self, key: key, value: value)
  }
}

/// An element that has a modified environment.
@MainActor
protocol EnvironmentWrapper {
  /// Access the element's modified environment.
  func withEnvironment(_ perform: () -> Void)
}

extension EnvironmentKey {
  // A hashable key based on the Environment value's type.
  fileprivate static var key: String { String(describing: Self.self) }
}

/// A wrapper that captures the environment modifications so they can be
/// provided when the wrapped element requests the Environment value.
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

extension ElementEnvironmentWrapper: ObservableElement where T: ObservableElement {
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
}

/// A wrapper that captures the environment modifications so they can be
/// provided when the wrapped page requests the Environment value.
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