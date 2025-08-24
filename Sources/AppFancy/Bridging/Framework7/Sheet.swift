//
// Copyright © 2025 peter bohac. All rights reserved.
//

import JavaScriptKit

/// Wrapper that bridges the Framework7 Sheet widget to Swift.
/// https://framework7.io/docs/sheet-modal
@MainActor
protocol Sheet: ObservableElement {
  /// The unique id of this sheet. Default is no id.
  var id: HTMLId? { get }
  /// Optional toolbar content. Default is no toolbar.
  @ElementBuilder var toolbar: [Element] { get }
  /// The sheet content.
  @ElementBuilder var content: [Element] { get }
}

extension Sheet {
  var id: HTMLId? { nil }
  var toolbar: [Element] { [] }
  var body: Element {
    HTML(.div, id: id, classes: .sheet) {
      if toolbar.isEmpty == false {
        Toolbar { toolbar }
      }
      HTML(.div, classes: .toolbarInner) {
        content
      }
    }
  }
}

extension Sheet {
  /// Creates a sheet toolbar with a dismiss button in the trailing position.
  /// - Parameter label: Text label for the dismiss button.
  /// - Returns: Toolbar content.
  @ElementBuilder
  static func toolbarWithDismiss(label: String) -> [Element] {
    HTML(.div, classes: .left)
    HTML(.div, classes: .right) {
      Link(label, classes: [.sheetClose]) {}
    }
  }
}

extension HTMLClass {
  static let sheet: Self = "sheet-modal"
  static let sheetInner: Self = "sheet-modal-inner"
  static let sheetClose: Self = "sheet-close"
}