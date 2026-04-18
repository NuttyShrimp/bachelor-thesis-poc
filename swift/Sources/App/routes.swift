import Hummingbird
import Logging

func buildRouter(logger: Logger) throws -> Router<MyRequestContext> {
    let router = Router(context: MyRequestContext.self)  // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }

    let benchmarkService = BenchmarkService(logger: logger)

    let apiGroup = router.group("/api")

    BenchmarkController(benchmark: benchmarkService, logger: logger).addRoutes(to: apiGroup)

    return router
}
