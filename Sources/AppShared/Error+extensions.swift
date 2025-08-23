//
// Copyright © 2025 peter bohac. All rights reserved.
//

public extension Error {
  /// A useful routine that captures more details about an error when logging it as a string.
  var message: String {
    String(describing: self)
  }
}