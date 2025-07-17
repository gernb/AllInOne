import ArgumentParser
import Hummingbird
import Logging

@main
struct Server: AsyncParsableCommand, AppArguments {
  var serverName = "app_server"

  @Option(name: .shortAndLong)
  var hostname: String = "127.0.0.1"

  @Option(name: .shortAndLong)
  var port: Int = 9100

  @Option(name: .shortAndLong)
  var logLevel: Logger.Level?

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
}

extension Logger.Level: @retroactive ExpressibleByArgument {}
