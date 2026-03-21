import Hummingbird
import Metrics
import Tracing

func buildRouter() throws -> Router<AppRequestContext> {
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

    let apiGroup = router.group("/api")

    BenchmarkController().addRoutes(to: apiGroup)

    return router
}
