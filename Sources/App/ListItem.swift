import ElementaryDOM

@View
struct ListItem {
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

  var content: some View {
    div(.style("display: flex; margin: 10px 0; max-width: 350px;")) {
      div(.style("display: flex; flex-grow: 1; align-items: center;")) {
        img(.src(image), .height(40))
        span(.style("margin: 0 10px;")) { label }
      }
      .onClick { _ in itemTapped() }
      img(.src("/trash-can.png"), .height(40))
        .onClick { _ in trashTapped() }
    }
  }
}
