//
// Copyright © 2025 peter bohac. All rights reserved.
//

import Foundation
import Hummingbird
import Logging

/// Application request context
typealias AppRequestContext = BasicRequestContext

/// Creates a new server application.
/// - Parameter arguments: Command-line arguments used to customise the configuration.
/// - Returns: A new server app that can be run.
func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
  let environment = Environment()
  let logger = {
    var logger = Logger(label: arguments.serverName)
    logger.logLevel =
      arguments.logLevel ?? environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) }
      ?? .info
    return logger
  }()
  let router = try buildRouter(logger: logger, dataPath: arguments.dataPath)
  var app = Application(
    router: router,
    configuration: .init(
      address: .hostname(arguments.hostname, port: arguments.port),
      serverName: arguments.serverName
    ),
    logger: logger
  )
  if arguments.browserSync {
    app.addServices(
      BrowserSyncService(port: arguments.port, logger: logger)
    )
  }
  return app
}

/// Builds a server router that serves static files from CWD + `/public`, reads and writes files
/// for the server API from CWD + `dataPath`, and logs all server requests.
/// - Parameters:
///   - logger: The logger instance to use.
///   - dataPath: The root path for the file server, relative to the current working directory.
/// - Returns: A configured server router.
private func buildRouter(logger: Logger, dataPath: String) throws -> Router<AppRequestContext> {
  let router = Router(context: AppRequestContext.self)
  let path = FileManager.default.currentDirectoryPath + "/public"
  router.addMiddleware {
    LogRequestsMiddleware(.info)
    FileMiddleware(
      path,
      searchForIndexHtml: true,
      logger: logger
    )
  }
  try FileController(dataPath: dataPath).addRoutes(to: router.group("api/v1/files"))
  return router
}
