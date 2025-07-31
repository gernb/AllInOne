import AppShared
import JavaScriptKit

@MainActor
struct ListItem: View {
  private let label: String
  private let image: String
  private let itemTapped: () -> Void
  private let trashTapped: () -> Void

  init(
    _ label: String,
    isFolder: Bool = false,
    itemTapped: @escaping () -> Void = {},
    trashTapped: @escaping () -> Void = {}
  ) {
    self.label = label
    self.image = DOM.locationPath + (isFolder ? "/folder.png" : "/file.png")
    self.itemTapped = itemTapped
    self.trashTapped = trashTapped
  }

  var body: JSValue {
    DOM.create("div") { body in
      body.style = "display: flex; margin: 10px 0; max-width: 350px;"

      DOM.addNew("div", to: body) { div in
        div.style = "display: flex; flex-grow: 1; align-items: center;"
        div.onClick(itemTapped)
        DOM.addNew("img", to: div) {
          $0.src = .string(image)
          $0.height = 40
        }
        DOM.addNew("span", to: div) {
          $0.style = "margin: 0 10px;"
          $0.innerText = .string(label)
        }
      }

      DOM.addNew("img", to: body) {
        $0.src = .string(DOM.locationPath + "/trash-can.png")
        $0.height = 40
        $0.onClick(trashTapped)
      }
    }
  }
}
