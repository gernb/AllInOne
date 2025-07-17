import ElementaryDOM
import Foundation
@preconcurrency import JavaScriptKit

@View
struct MainView {
  @State private var showSomething = false
  private let clientApi = ClientAPI.live

  var content: some View {
    if showSomething {
      div {
        p { "Something" }
      }
    }
    div {
      p { "Hello, world!" }
      button { showSomething ? "Hide element" : "Show element" }
        .onClick { _ in
          showSomething.toggle()
          //   JSObject.global.alert!("Button clicked!")
          Task { [clientApi] in
            do {
              // let root = try await clientApi.folderListing("/")
              // print(root)
              struct File: Codable {
                let name: String
                let version: String
              }
              // if let (data, etag) = try await clientApi.fetch(path: "/file1.json", ifNotMatching: "W/\"122-1969daf00dd\"") {
              //   let file = try JSONDecoder().decode(File.self, from: data)
              //   print(file, etag)
              // }
              // try await clientApi.delete(file: "/file1.json")
              // print("done")
              let tag = try await clientApi.put(
                object: File(name: "peter", version: "0.5.6"), at: "/file.json")
              print(tag)
            } catch {
              print("Error:", String(describing: error))
            }
          }
        }
    }
    .onMount {
      // print("mounted")
    }
  }
}
