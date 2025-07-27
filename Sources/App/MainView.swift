@preconcurrency import JavaScriptKit
import SwiftNavigation

@MainActor
final class MainView: View {
  private let model = MainViewModel()
  private var tokens: Set<ObserveToken> = []

  var body: JSValue {
    let body = App.doc.createElement("div")

    let path = App.doc.createElement("h2")
    body.addElement(path)

    let backButton = App.doc.createElement("img")
    backButton.src = "/back.png"
    backButton.height = 40
    backButton.style = "display: none;"
    backButton.onclick = .object(
      JSClosure { [model] _ in
        model.path.removeLast()
        return .undefined
      }
    )
    body.addElement(backButton)

    let list = App.doc.createElement("div")
    body.addElement(list)

    observe { [model] in
      path.innerText = .string(model.pathString)
      backButton.style = model.path.isEmpty ? "display: none;" : "display: inline;"

      let listContents = App.doc.createElement("div")
      for folder in model.folders {
        let item = ListItem(folder, isFolder: true) {
          model.path.append(folder)
        } trashTapped: {
          App.alert("delete '\(folder)'")
        }
        listContents.addElement(item.body)
      }
      for file in model.files {
        let item = ListItem(file) {
          App.alert("'\(file)' tapped")
        } trashTapped: {
          App.alert("delete '\(file)'")
        }
        listContents.addElement(item.body)
      }
      _ = list.replaceChildren(listContents)
    }
    .store(in: &tokens)

    return body
  }

  func onAdded() {
    model.fetchCurrentDirectory()
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
        let response = try await clientApi.folderListing(pathString)
        folders = response.directories
        files = response.files
      } catch {
        App.alert(error.message)
      }
    }
  }
}