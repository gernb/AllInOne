//
// Copyright © 2025 peter bohac. All rights reserved.
//

import AppShared
@preconcurrency import JavaScriptKit

/// A View that renders the app main UI.
/// This implementation simply replaces the list content when navigating in/out of a folder.
struct MainView: View {
  /// The view model
  private let model = MainViewModel()
  /// The UI label that displays the current path
  private let pathLabel = DOM.create("h2") {
    $0.style = "flex-grow: 1;"
  }
  /// The UI label that displays the time stamp of the last update from the server
  private let timestampLabel = DOM.create("span")
  /// UI button to navigate "up" one level
  private let backButton = DOM.create("img") {
    $0.src = .string(DOM.locationPath + "/back.png")
    $0.height = 40
    $0.style = "display: none;"
  }
  /// UI element for the folder contents
  private let list = DOM.create("div")
  /// UI element for the "new folder" dialog
  private let dialog = DOM.create("dialog") { createFolderDialog($0) }

  private enum Constants {
    static let width = 350
  }

  func render() -> JSValue {
    DOM.create("div") { body in
      body.style = "display: flex; justify-content: center;"

      DOM.addNew("div", to: body) { content in
        content.style = .string("max-width: \(Constants.width)px;")

        DOM.addNew("div", to: content) { div in
          div.style = .string("display: flex; align-items: center; width: \(Constants.width)px;")
          DOM.addElement(pathLabel, to: div)
          DOM.addNew("img", to: div) {
            $0.src = .string(DOM.locationPath + "/synchronize.png")
            $0.height = 30
            $0.onClick {
              model.fetchCurrentDirectory()
            }
          }
        }
        DOM.addElement(backButton, to: content)
        backButton.onClick {
          model.path.removeLast()
        }
        DOM.addElement(list, to: content)
        DOM.addElement(timestampLabel, to: content)
        DOM.addNew("br", to: content)
        DOM.addNew("button", to: content) {
          $0.style = "margin: 5px 0; height: 40px;"
          $0.innerText = "Create New Folder"
          $0.onClick {
            _ = dialog.showModal()
          }
        }
        DOM.addNew("br", to: content)
        let fileInput = DOM.addNew("input", to: content) { input in
          input.style = "display: none;"
          input.type = "file"
          input.event("change") { [model] in
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
        DOM.addNew("button", to: content) {
          $0.style = "margin: 5px 0; height: 40px;"
          $0.innerText = "Upload File"
          $0.onClick {
            _ = fileInput.click()
          }
        }
      }

      DOM.addElement(dialog, to: body)
      dialog.event("close") {
        if let folderName = dialog.returnValue.string, folderName.isEmpty == false {
          model.createFolder(folderName)
        }
      }
    }
  }

  func observing() {
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

  func onAdded() {
    // Get the folder contents for the current path
    model.fetchCurrentDirectory()
  }

  /// Creates a browser dialog for getting the new folder name from the user.
  private static func createFolderDialog(_ dialog: JSValue) {
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