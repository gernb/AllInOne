//
// Copyright © 2025 peter bohac. All rights reserved.
//

import AppShared
import JavaScriptEventLoop

/// The application entrypoint.
@MainActor
@main
struct App {
  static func main() {
    // This is necessary to allow the observation code to work.
    JavaScriptEventLoop.installGlobalExecutor()
    // Replace the "loading" content in index.html with our app content.
    DOM.addView(MainView(), to: DOM.doc.body, replace: true)
  }
}