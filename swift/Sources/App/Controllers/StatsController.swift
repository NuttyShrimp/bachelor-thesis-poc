import Hummingbird
import Metrics
import Prometheus

struct StatsController: Sendable {
    func addRoutes(to group: RouterGroup<MyRequestContext>) {
        group
            .group("/prometheus")
            .get(use: self.stats)
    }

    func stats(_ request: Request, ctx: MyRequestContext) async throws -> String {
        guard let factory = MetricsSystem.factory as? PrometheusMetricsFactory else {
            throw HTTPError.init(.internalServerError)
        }
        return factory.registry.emitToString()
    }
}
