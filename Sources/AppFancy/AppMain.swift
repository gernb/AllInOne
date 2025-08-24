//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptEventLoop

/// Application entrypoint
@MainActor
@main
struct AppMain {
  static var debugConsoleModel: DebugConsoleModel?

  static func main() {
    // This is necessary for the observation code to function.
    JavaScriptEventLoop.installGlobalExecutor()
#if DEBUG
    // Only show a debug console on debug builds.
    debugConsoleModel = .init()
#endif
    print("Running v\(AppVersion)…")
    App.setup()
    // Create and add a common navbar
    let navbar = NavBar(title: "Mobile File Browser")
    View.main.insert(element: navbar, before: "loadingPage")
    // Navigate to the primary app UI
    View.main.navigate(to: FolderListing(), transition: .flip)
  }
}