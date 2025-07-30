import Foundation
import Logging
import ServiceLifecycle

struct BrowserSyncService: Service {
  let port: Int
  let logger: Logger

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
