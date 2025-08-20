import JavaScriptKit

struct Breadcrumbs: Element {
  let items: [Element]

  init(_ items: [Element]) {
    self.items = items
  }

  init(_ items: [String]) {
    self.init(
      items.map { text in
        HTML(.div) { $1.innerText = .string(text) }
      }
    )
  }

  init(_ items: [(label: String, icon: F7Icon?)]) {
    self.init(
      items.map { (text, icon) in
        HTML(.div) {
          if let icon {
            Icon(icon)
            HTML(.span) {
              $1.style.marginLeft = "5px"
              $1.innerText = .string(text)
            }
          } else {
            HTML(.span) { $1.innerText = .string(text) }
          }
        }
      }
    )
  }

  var body: Element {
    HTML(.div, classes: .breadcrumbs) {
      if let first = items.first {
        let classes: [HTMLClass] = items.count == 1 ? [.breadcrumbsItem, .breadcrumbsItemActive] : [.breadcrumbsItem]
        first.addingClasses(classes)
        for (index, item) in items.enumerated().dropFirst() {
          HTML(.div, classes: .breadcrumbsSeparator)
          let classes: [HTMLClass] = index == (items.count - 1) ? [.breadcrumbsItem, .breadcrumbsItemActive] : [.breadcrumbsItem]
          item.addingClasses(classes)
        }
      }
    }
  }
}

extension HTMLClass {
  static let breadcrumbs: Self = "breadcrumbs"
  static let breadcrumbsItem: Self = "breadcrumbs-item"
  static let breadcrumbsItemActive: Self = "breadcrumbs-item-active"
  static let breadcrumbsSeparator: Self = "breadcrumbs-separator"
}