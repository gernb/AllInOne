//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptEventLoop

/// Application entrypoint
@MainActor
@main
struct AppMain {
  static func main() {
    // This is necessary for the observation code to function.
    JavaScriptEventLoop.installGlobalExecutor()
    print("Running…")
    App.setup()
    // Create and add a common navbar
    let navbar = NavBar(title: "Mobile File Browser")
    View.main.insert(element: navbar, before: "loadingPage")
    // Navigate to the primary app UI
    View.main.navigate(to: FolderListing(), transition: .flip)
  }
}