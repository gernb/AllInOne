public extension Error {
  var message: String {
    String(describing: self)
  }
}