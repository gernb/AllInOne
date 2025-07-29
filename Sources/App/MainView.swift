@preconcurrency import JavaScriptKit
import SwiftNavigation

@MainActor
final class MainView: View {
  private let model = MainViewModel()
  private var tokens: Set<ObserveToken> = []

  var body: JSValue {
    let body = DOM.create("div")

    let pathLabel = DOM.create("h2") {
      $0.style = "display: flex; flex-grow: 1;"
    }

    DOM.addNew("div", to: body) { div in
      div.style = "display: flex; max-width: 350px; align-items: center;"
      DOM.addElement(pathLabel, to: div)
      DOM.addNew("img", to: div) {
        $0.src = "/synchronize.png"
        $0.height = 30
        $0.onClick { [model] in
          model.fetchCurrentDirectory()
        }
      }
    }

    let backButton = DOM.addNew("img", to: body) {
      $0.src = "/back.png"
      $0.height = 40
      $0.style = "display: none;"
      $0.onClick { [model] in
        model.path.removeLast()
      }
    }

    let list = DOM.addNew("div", to: body)
    let timestampLabel = DOM.addNew("span", to: body)
    DOM.addNew("br", to: body)

    let dialog = DOM.addNew("dialog", to: body, builder: createFolderDialog)
    dialog.on("close") { [model] in
      if let folderName = dialog.returnValue.string, folderName.isEmpty == false {
        model.createFolder(folderName)
      }
    }
    DOM.addNew("button", to: body) {
      $0.style = "margin: 5px 0;"
      $0.innerText = "Create New Folder"
      $0.onClick {
        _ = dialog.showModal()
      }
    }

    DOM.addNew("br", to: body)
    let fileInput = DOM.addNew("input", to: body) { input in
      input.style = "display: none;"
      input.type = "file"
      input.on("change") { [model] in
        guard let files = input.object?.files,
              files.length == 1,
              let file = files[0].object
        else {
          DOM.alert("There was an unexpected issue preparing your file.")
          return
        }
        model.upload(file)
      }
    }
    DOM.addNew("button", to: body) {
      $0.style = "margin: 5px 0;"
      $0.innerText = "Upload File"
      $0.onClick {
        _ = fileInput.click()
      }
    }

    observe { [model] in
      pathLabel.innerText = .string(model.pathString)
      if let timestamp = model.lastFetchTimestamp {
        let value = timestamp.formatted(date: .abbreviated, time: .standard)
        timestampLabel.innerText = .string("Last updated: \(value)")
      }
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
            model.download(file: file)
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