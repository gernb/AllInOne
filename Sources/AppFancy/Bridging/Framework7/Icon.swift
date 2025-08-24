//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Icon widget to Swift.
/// https://framework7.io/docs/icons
struct Icon: Element {
  let iOSIcon: String
  let mdIcon: String

  /// Creates a new `Icon` with the specified iOS and MD icon names.
  /// - Parameters:
  ///   - iOSIcon: The icon name to use for iOS.
  ///   - mdIcon: The icon name to use for Material Design; default is to use the iOS name if not provided.
  init(iOSIcon: String, mdIcon: String? = nil) {
    self.iOSIcon = iOSIcon
    self.mdIcon = mdIcon ?? iOSIcon
  }

  /// Creates a new `Icon` with the specified Framework7 icon.
  /// https://framework7.io/icons/
  /// - Parameter icon: The F7 icon to use; these auto-adapt for the appropriate iOS or MD version.
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

/// https://framework7.io/icons/
enum F7Icon: String {
  case arrowUpDoc = "arrow_up_doc"
  case arrowUpDocFill = "arrow_up_doc_fill"
  case chevronRight = "chevron_right"
  case docPlaintext = "doc_plaintext"
  case docText = "doc_text"
  case docTextFill = "doc_text_fill"
  case ellipsis
  case exclamationmark
  case exclamationmarkCircle = "exclamationmark_circle"
  case exclamationmarkCircleFill = "exclamationmark_circle_fill"
  case folder
  case folderBadgePlus = "folder_badge_plus"
  case folderFill = "folder_fill"
  case folderFillBadgePlus = "folder_fill_badge_plus"
  case house
  case info
  case infoCircle = "info_circle"
  case infoCircleFill = "info_circle_fill"
  case lineHorizontal3 = "line_horizontal_3"
  case listBelowRectangle = "list_bullet_below_rectangle"
  case question
  case questionCircle = "question_circle"
  case questionCircleFill = "question_circle_fill"
  case tag
  case tagCircle = "tag_circle"
  case tagCircleFill = "tag_circle_fill"
  case xmark
  case xmarkCircle = "xmark_circle"
  case xmarkCircleFill = "xmark_circle_fill"

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