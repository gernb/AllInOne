import JavaScriptEventLoop

@MainActor
@main
struct AppMain {
  static func main() {
    JavaScriptEventLoop.installGlobalExecutor()
    print("Running…")
    App.setup()
    let navbar = NavBar(title: "Mobile File Browser")
    View.main.insert(element: navbar, before: "loadingPage")
    View.main.navigate(to: FolderListing(), transition: .flip)
  }
}