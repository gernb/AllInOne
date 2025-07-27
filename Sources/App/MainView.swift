@preconcurrency import JavaScriptKit
import SwiftNavigation

@MainActor
final class MainView: View {
  private let model = MainViewModel()
  private var tokens: Set<ObserveToken> = []

  var body: JSValue {
    let body = DOM.create("div")

    let pathLabel = DOM.addNew("h2", to: body)

    let backButton = DOM.addNew("img", to: body) {
      $0.src = "/back.png"
      $0.height = 40
      $0.style = "display: none;"
      $0.onClick { [model] in
        model.path.removeLast()
      }
    }

    let list = DOM.addNew("div", to: body)

    let dialog = DOM.addNew("dialog", to: body, builder: createFolderDialog)
    dialog.on("close") { [model] in
      if let folderName = dialog.returnValue.string, folderName.isEmpty == false {
        model.createFolder(folderName)
      }
    }
    DOM.addNew("button", to: body) {
      $0.innerText = "Create New Folder"
      $0.onClick {
        _ = dialog.showModal()
      }
    }

    observe { [model] in
      pathLabel.innerText = .string(model.pathString)
      backButton.style = model.path.isEmpty ? "display: none;" : "display: inline;"

      DOM.addNew("div", to: list, replace: true) { list in
        for folder in model.folders {
          let item = ListItem(folder, isFolder: true) {
            model.path.append(folder)
          } trashTapped: {
            let confirmed = DOM.window.confirm("Do you want to delete '\(folder)'?").boolean!
            if confirmed {
              model.delete(folder)
            }
          }
          DOM.addView(item, to: list)
        }
        for file in model.files {
          let item = ListItem(file) {
            DOM.alert("'\(file)' tapped")
          } trashTapped: {
            let confirmed = DOM.window.confirm("Do you want to delete '\(file)'?").boolean!
            if confirmed {
              model.delete(file)
            }
          }
          DOM.addView(item, to: list)
        }
      }
    }
    .store(in: &tokens)

    return body
  }

  func onAdded() {
    model.fetchCurrentDirectory()
  }

  private func createFolderDialog(_ dialog: JSValue) {
    let input = DOM.create("input") {
      $0.type = "text"
    }
    DOM.addNew("label", to: dialog) {
      $0.innerText = "Folder name:"
      DOM.addElement(input, to: $0)
    }
    DOM.addNew("div", to: dialog) { div in
      div.style = "display: flex; justify-content: space-evenly; margin-top: 5px"
      DOM.addNew("button", to: div) {
        $0.innerText = "Cancel"
        $0.onClick {
          _ = dialog.close()
        }
      }
      DOM.addNew("button", to: div) {
        $0.innerText = "Ok"
        $0.onClick {
          guard let folderName = input.value.string?.trimmingCharacters(in: .whitespaces),
            folderName.isEmpty == false
          else {
            return
          }
          _ = dialog.close(folderName)
        }
      }
    }
  }
}

@MainActor
@Perceptible
final class MainViewModel {
  var path: [String] = [] {
    didSet {
      fetchCurrentDirectory()
    }
  }
  private(set) var folders: [String] = []
  private(set) var files: [String] = []

  var pathString: String {
    "/" + path.joined(separator: "/")
  }

  private let clientApi = ClientAPI.live

  func fetchCurrentDirectory() {
    Task {
      do {
        try await fetchCurrentDirectory()
      } catch {
        DOM.alert(error.message)
      }
    }
  }

  func delete(_ item: String) {
    Task {
      do {
        let itemPath = pathString + "/" + item
        try await clientApi.delete(path: itemPath)
        try await fetchCurrentDirectory()
      } catch {
        DOM.alert(error.message)
      }
    }
  }

  func createFolder(_ name: String) {
    Task {
      do {
        try await clientApi.createFolder(at: pathString + "/" + name)
        try await fetchCurrentDirectory()
      } catch {
        DOM.alert(error.message)
      }
    }
  }

  private func fetchCurrentDirectory() async throws {
    let response = try await clientApi.folderListing(pathString)
    folders = response.directories
    files = response.files
  }
}