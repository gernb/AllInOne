//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit
import SwiftNavigation

/// An application sheet that displays the JavaScript console log.
/// This can be useful when debugging on Mobile Safari.
struct DebugConsoleSheet: Sheet {
  let model: DebugConsoleModel

  var toolbar: [Element] {
    HTML(.div, classes: .left) {
      Link("Clear") {
        model.clear()
      }
    }
    HTML(.div, classes: .right) {
      Link("Close", classes: [.sheetClose]) {}
    }
  }

  var content: [ Element] {
    HTML(.div, id: container, classes: .pageContent) {
      $1.style.width = "100vw"
    } containing: {
      List(id: list)
    }
  }

  private let container = IdentifiedNode()
  private let list = IdentifiedNode()

  func observing() {
    list.clear()
    for log in model.logs {
      list.add(
        ListItem(title: log.message, icon: log.icon)
      )
    }
    container.node.scrollTop = container.node.scrollHeight
  }
}

extension DebugConsoleModel.Entry {
  var icon: F7Icon {
    switch level {
    case .log: .tagCircleFill
    case .info: .infoCircleFill
    case .warn: .exclamationmarkCircleFill
    case .error: .xmarkCircleFill
    }
  }
}

@Perceptible
@MainActor
final class DebugConsoleModel {
  @PerceptionIgnored
  private let globalLog: JSValue
  @PerceptionIgnored
  private let globalWarn: JSValue
  @PerceptionIgnored
  private let globalInfo: JSValue
  @PerceptionIgnored
  private let globalError: JSValue

  private(set) var logs: [Entry] = []

  init() {
    self.globalLog = JSObject.global.console.log
    self.globalWarn = JSObject.global.console.warn
    self.globalInfo = JSObject.global.console.info
    self.globalError = JSObject.global.console.error
    interceptConsole()
  }

  deinit {
    JSObject.global.console.log = globalLog
    JSObject.global.console.warn = globalWarn
    JSObject.global.console.info = globalInfo
    JSObject.global.console.error = globalError
  }

  func clear() {
    logs.removeAll()
  }

  private func interceptConsole() {
    // let console = JSObject.global.console
    JSObject.global.console.log =
      JSClosure { [weak self] args in
        self?.logs.append(Entry(level: .log, args: args))
        // _ = globalLog.function?.apply.function?(console, args)
        if args.count == 1 {
          _ = self?.globalLog.function?(args[0])
        } else {
          _ = self?.globalLog.function?(args)
        }
        return .undefined
      }
      .jsValue
    JSObject.global.console.warn =
      JSClosure { [weak self] args in
        self?.logs.append(Entry(level: .warn, args: args))
        // _ = globalLog.function?.apply.function?(console, args)
        if args.count == 1 {
          _ = self?.globalWarn.function?(args[0])
        } else {
          _ = self?.globalWarn.function?(args)
        }
        return .undefined
      }
      .jsValue
    JSObject.global.console.info =
      JSClosure { [weak self] args in
        self?.logs.append(Entry(level: .info, args: args))
        // _ = globalLog.function?.apply.function?(console, args)
        if args.count == 1 {
          _ = self?.globalInfo.function?(args[0])
        } else {
          _ = self?.globalInfo.function?(args)
        }
        return .undefined
      }
      .jsValue
    JSObject.global.console.error =
      JSClosure { [weak self] args in
        self?.logs.append(Entry(level: .error, args: args))
        // _ = globalLog.function?.apply.function?(console, args)
        if args.count == 1 {
          _ = self?.globalError.function?(args[0])
        } else {
          _ = self?.globalError.function?(args)
        }
        return .undefined
      }
      .jsValue
  }
}

extension DebugConsoleModel {
  enum Level {
    case log, info, warn, error
  }
  struct Entry {
    let level: Level
    let message: String

    init(level: Level, message: String) {
      self.level = level
      self.message = message
    }
    init(level: Level, args: [JSValue]) {
      self.level = level
      self.message = args.map {
        String(describing: $0)
      }
      .joined(separator: " ")
    }
  }
}