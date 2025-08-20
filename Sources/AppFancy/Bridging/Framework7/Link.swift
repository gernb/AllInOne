import JavaScriptKit

struct Link: Element {
  let id: HTMLId?
  let classes: [HTMLClass]
  let content: HTML.Contents
  let action: (() -> Void)?

  init(
    _ label: String,
    id: HTMLId? = nil,
    classes: [HTMLClass] = [],
    action: @escaping () -> Void
  ) {
    self.init(id: id, classes: classes, action: action) {
      HTML(.span) {
        $1.innerText = .string(label)
      }
    }
  }

  init(
    id: HTMLId? = nil,
    action: @escaping () -> Void,
    @ElementBuilder content: @escaping HTML.Contents
  ) {
    self.init(id: id, classes: [], action: action, content: content)
  }

  init(
    id: HTMLId? = nil,
    classes: [HTMLClass],
    action: (() -> Void)? = nil,
    @ElementBuilder content: @escaping HTML.Contents
  ) {
    self.id = id
    self.classes = classes
    self.action = action
    self.content = content
  }

  var body: Element {
    HTML(
      .a,
      id: id,
      classList: classList,
      builder: {
        $1.href = "#"
        if let action {
          _ = $1.addEventListener(
            "click",
            JSClosure { _ in
              action()
              return .undefined
            }
          )
        }
      },
      containing: content
    )
  }

  private var classList: [HTMLClass] {
    if Environment[Popover.InsidePopover.self] {
      [.link, .popoverClose] + classes
    } else {
      [.link] + classes
    }
  }
}

extension HTMLClass {
  static let link: Self = "link"
}
