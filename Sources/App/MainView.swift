import ElementaryDOM
import Foundation
@preconcurrency import JavaScriptKit

@View
struct MainView {
  private let clientApi = ClientAPI.live
  private let alert = JSObject.global.alert.function!

  @State private var path: [String] = [] {
    didSet {
      // alert(pathString)
      fetchCurrentDirectory()
    }
  }
  @State private var folders: [String] = []
  @State private var files: [String] = []

  private var pathString: String {
    "/" + path.joined(separator: "/")
  }

  var content: some View {
    h2 { pathString }
    div {
      if path.isEmpty == false {
        img(.src("/back.png"), .height(40))
          .onClick { _ in
            path.removeLast()
          }
      }
      for folder in folders {
        ListItem(folder, isFolder: true) {
          path.append(folder)
        } trashTapped: {
          alert("delete '\(folder)'")
        }
      }
      for file in files {
        ListItem(file) {
          alert("'\(file)' tapped")
        } trashTapped: {
          alert("delete '\(file)'")
        }
      }

      // button { showSomething ? "Hide element" : "Show element" }
      //   .onClick { _ in
      //     showSomething.toggle()
      //     //   JSObject.global.alert!("Button clicked!")
      //     Task { [clientApi] in
      //       do {
      //         // let root = try await clientApi.folderListing("/")
      //         // print(root)
      //         struct File: Codable {
      //           let name: String
      //           let version: String
      //         }
      //         // if let (data, etag) = try await clientApi.fetch(path: "/file1.json", ifNotMatching: "W/\"122-1969daf00dd\"") {
      //         //   let file = try JSONDecoder().decode(File.self, from: data)
      //         //   print(file, etag)
      //         // }
      //         // try await clientApi.delete(file: "/file1.json")
      //         // print("done")
      //         let tag = try await clientApi.put(
      //           object: File(name: "peter", version: "0.5.6"),
      //           at: "/file.json"
      //         )
      //         print(tag)
      //       } catch {
      //         print("Error:", String(describing: error))
      //       }
      //     }
      //   }
    }
    .onMount {
      // print("mounted")
      fetchCurrentDirectory()
    }
  }

  private func fetchCurrentDirectory() {
    Task { @MainActor [clientApi, pathString] in
      do {
        let response = try await clientApi.folderListing(pathString)
        folders = response.directories
        files = response.files
      } catch {
        print(error)
      }
    }
  }
}
