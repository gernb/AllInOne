//
// Copyright © 2025 peter bohac. All rights reserved.
//

import Foundation
import Logging
import ServiceLifecycle

/// A service that uses the `browser-sync` application (if it is installed) to
/// proxy web traffic and hot-reload the content when it receives a reload signal.
struct BrowserSyncService: Service {
  /// The local port the web server is listening on.
  let port: Int
  /// The logging instance to use.
  let logger: Logger

  /// The entrypoint for this service.
  func run() async throws {
    let task = Task {
      while Task.isCancelled == false {
        try? await Task.sleep(for: .seconds(3600))
      }
    }
    await withGracefulShutdownHandler {
      do {
        let p = Process()
        p.executableURL = URL(string: "file:///bin/sh")
        p.arguments = ["-c", "browser-sync start --proxy 127.0.0.1:\(port)"]
        try p.run()

        await task.value

        let pkill = Process()
        pkill.executableURL = URL(string: "file:///bin/sh")
        pkill.arguments = ["-c", "pkill -P \(p.processIdentifier)"]
        try pkill.run()

        logger.info("Terminated browser-sync process")
      } catch {
        logger.error("Could not start browser-sync: \(error)")
      }
    } onGracefulShutdown: {
      task.cancel()
    }
  }
}
