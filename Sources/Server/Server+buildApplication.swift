import Foundation
import Hummingbird
import Logging

typealias AppRequestContext = BasicRequestContext

func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
  let environment = Environment()
  let logger = {
    var logger = Logger(label: arguments.serverName)
    logger.logLevel =
      arguments.logLevel ?? environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) }
      ?? .info
    return logger
  }()
  let router = buildRouter(logger: logger)
  let app = Application(
    router: router,
    configuration: .init(
      address: .hostname(arguments.hostname, port: arguments.port),
      serverName: arguments.serverName
    ),
    logger: logger
  )
  return app
}

func buildRouter(logger: Logger) -> Router<AppRequestContext> {
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
  router.get("/hello") { _, _ in
    return "Hello!"
  }
  return router
}
