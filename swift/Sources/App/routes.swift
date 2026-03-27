import Hummingbird
import Logging
import Metrics
import SystemMetrics
import Tracing

func buildRouter(logger: Logger) throws -> Router<MyRequestContext> {
    let router = Router(context: MyRequestContext.self)  // Add middleware
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
