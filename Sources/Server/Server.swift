import ArgumentParser
import Hummingbird
import Logging

@main
struct Server: AsyncParsableCommand, AppArguments {
  var serverName = "app_server"

  @Option(name: .shortAndLong)
  var hostname: String = "0.0.0.0"

  @Option(name: .shortAndLong)
  var port: Int = 80

  @Option(name: .shortAndLong)
  var logLevel: Logger.Level?

  @Option(name: .shortAndLong)
  var dataPath: String = "data"

  func run() async throws {
    let app = try await buildApplication(self)
    try await app.runService()
  }
}

protocol AppArguments {
  var serverName: String { get }
  var hostname: String { get }
  var port: Int { get }
  var logLevel: Logger.Level? { get }
  var dataPath: String { get }
}

extension Logger.Level: @retroactive ExpressibleByArgument {}
