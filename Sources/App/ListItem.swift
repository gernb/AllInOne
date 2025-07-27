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
    self.image = isFolder ? "/folder.png" : "/file.png"
    self.itemTapped = itemTapped
    self.trashTapped = trashTapped
  }

  var body: JSValue {
    let body = App.doc.createElement("div")
    body.style = "display: flex; margin: 10px 0; max-width: 350px;"

    let itemDiv = App.doc.createElement("div")
    itemDiv.style = "display: flex; flex-grow: 1; align-items: center;"
    itemDiv.onclick = .object(
      JSClosure { _ in
        itemTapped()
        return .undefined
      }
    )
    body.addElement(itemDiv)

    let img = App.doc.createElement("img")
    img.src = .string(image)
    img.height = 40
    itemDiv.addElement(img)

    let span = App.doc.createElement("span")
    span.style = "margin: 0 10px;"
    span.innerText = .string(label)
    itemDiv.addElement(span)

    let trashImg = App.doc.createElement("img")
    trashImg.src = "/trash-can.png"
    trashImg.height = 40
    trashImg.onclick = .object(
      JSClosure { _ in
        trashTapped()
        return .undefined
      }
    )
    body.addElement(trashImg)

    return body
  }
}
