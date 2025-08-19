import JavaScriptKit

struct Icon: Element {
  let icon: String

  init(_ icon: String) {
    self.icon = icon
  }
  init(_ icon: F7Icon) {
    self.init(icon.rawValue)
  }
  init(_ icon: any RawRepresentable<String>) {
    self.init(icon.rawValue)
  }

  var body: Element {
    HTML(.span) {
      HTML(.i, classes: .icon, .f7Icons, .ifNotMD) {
        $1.innerText = .string(icon)
      }
      HTML(.i, classes: .icon, .materialIcons, .mdOnly) {
        $1.innerText = .string(icon)
      }
    }
  }
}

extension HTMLClass {
  static let icon: Self = "icon"
  static let f7Icons: Self = "f7-icons"
  static let materialIcons: Self = "material-icons"
  static let ifNotMD: Self = "if-not-md"
  static let mdOnly: Self = "md-only"
}

enum F7Icon: String {
  case arrowUpDoc = "arrow_up_doc"
  case arrowUpDocFill = "arrow_up_doc_fill"
  case docPlaintext = "doc_plaintext"
  case docText = "doc_text"
  case docTextFill = "doc_text_fill"
  case ellipsis
  case folder
  case folderBadgePlus = "folder_badge_plus"
  case folderFill = "folder_fill"
  case folderFillBadgePlus = "folder_fill_badge_plus"
  case house
  case lineHorizontal3 = "line_horizontal_3"
}