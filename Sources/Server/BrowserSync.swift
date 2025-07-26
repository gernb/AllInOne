import Foundation

func browserSyncReload(port: Int) {
  #if DEBUG
    let p = Process()
    p.executableURL = URL(string: "file:///bin/sh")
    p.arguments = ["-c", "browser-sync start --proxy 127.0.0.1:\(port)"]
    do {
      try p.run()
    } catch {
      print("Could not auto-reload: \(error)")
    }
  #endif
}
