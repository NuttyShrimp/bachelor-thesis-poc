import Hummingbird
import Jobs
import JobsValkey
import Logging
import TestSuiteLibrary
import Valkey

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
package protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

struct AppRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage
    var requestDecoder: GeneralRequestDecoder { .init() }

    init(source: Source) {
        self.coreContext = .init(source: source)
    }
}

///  Build application
/// - Parameter arguments: application arguments
func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "test-suite")
        logger.logLevel =
            arguments.logLevel ?? environment.get("LOG_LEVEL").flatMap {
                Logger.Level(rawValue: $0)
            } ?? .info
        return logger
    }()

    let valkeyLogger = Logger(label: "Valkey")
    let valkeyHost = environment.get("VALKEY_HOST") ?? "localhost"
    let valkeyClient = ValkeyClient(.hostname(valkeyHost, port: 6379), logger: valkeyLogger)
    let jobQueue = try await JobQueue(
        .valkey(
            valkeyClient,
            configuration: .init(
                queueName: "bap-test-suite", retentionPolicy: .init(completedJobs: .retain)),
            logger: logger
        ),
        logger: logger
    )

    let jobService = JobService(jobQueue, logger: logger)

    let router = try buildRouter(logger, jobService)
    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "test-suite"
        ),
        logger: logger
    )
    app.addServices(jobService)
    return app
}

/// Build router
func buildRouter(_ logger: Logger, _ jobService: JobService) throws -> Router<
    AppRequestContext
> {
    let router = Router(context: AppRequestContext.self)
    // Middlewares
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }
    router.addMiddleware {
        FileMiddleware("Sources/App/public", logger: logger)
    }

    UIController(service: jobService).addRoutes(to: router.group())
    JobController(service: jobService).addRoutes(to: router.group("/job"))

    return router
}
