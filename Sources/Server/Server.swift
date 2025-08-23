//
// Copyright © 2025 peter bohac. All rights reserved.
//

import ArgumentParser
import Hummingbird
import Logging

/// The main server entrypoint.
@main
struct Server: AsyncParsableCommand, AppArguments {
  /// The name / identity of the server; primarily used in the log files.
  var serverName = "app_server"

  /// The IP address to listen on; default is to listen on all device IP addresses.
  @Option(name: .shortAndLong)
  var hostname: String = "0.0.0.0"

  /// The port to listen on; default is to listen on the standard web port (80).
  @Option(name: .shortAndLong)
  var port: Int = 80

  /// The logging level; if not specified the `LOG_LEVEL` environment value will be used;
  /// and if that is not specified the default level is `info`.
  @Option(name: .shortAndLong)
  var logLevel: Logger.Level?

  /// The path of the file server contents; default is `./data`.
  @Option(name: .shortAndLong)
  var dataPath: String = "data"

  /// Whether or not to attempt to start the Browser Sync process; default is `false`.
  @Flag(name: .shortAndLong)
  var browserSync = false

  /// Server entrypoint. Will not return until the server is cancelled.
  func run() async throws {
    let app = try await buildApplication(self)
    try await app.runService()
  }
}

/// The server command-line configuration arguments.
protocol AppArguments {
  var serverName: String { get }
  var hostname: String { get }
  var port: Int { get }
  var logLevel: Logger.Level? { get }
  var dataPath: String { get }
  var browserSync: Bool { get }
}

extension Logger.Level: @retroactive ExpressibleByArgument {}
