import JavaScriptKit

struct Icon: Element {
  let iOSIcon: String
  let mdIcon: String

  init(iOSIcon: String, mdIcon: String? = nil) {
    self.iOSIcon = iOSIcon
    self.mdIcon = mdIcon ?? iOSIcon
  }

  init(_ icon: F7Icon) {
    self.init(iOSIcon: icon.rawValue, mdIcon: icon.mdIcon)
  }

  var body: Element {
    HTML(.span) {
      HTML(.i, classes: .icon, .f7Icons, .ifNotMD) {
        $1.innerText = .string(iOSIcon)
      }
      HTML(.i, classes: .icon, .materialIcons, .mdOnly) {
        $1.innerText = .string(mdIcon)
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
  case chevronRight = "chevron_right"
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

  var mdIcon: String {
    switch self {
    case .arrowUpDoc: "upload_file"
    case .docTextFill: "text_snippet"
    case .folderBadgePlus: "create_new_folder"
    case .lineHorizontal3: "menu"
    default: rawValue
    }
  }
}