import Hummingbird
import Metrics
import Tracing
import Logging

func buildRouter(logger: Logger) throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // metrics middleware
        MetricsMiddleware()
        // tracing middleware
        TracingMiddleware()
        // logging middleware
        LogRequestsMiddleware(.info)
    }

    let benchmarkService = BenchmarkService(logger: logger)

    let apiGroup = router.group("/api")

    BenchmarkController(benchmark: benchmarkService).addRoutes(to: apiGroup)

    return router
}
