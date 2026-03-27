import Configuration
import Hummingbird
import Logging
import Metrics
import Prometheus
import SystemMetrics

// Request context used by application
typealias AppRequestContext = MyRequestContext

///  Build application
/// - Parameter reader: configuration reader
func buildApplication(reader: ConfigReader) async throws -> some ApplicationProtocol {
    let logger = {
        var logger = Logger(label: "bap")
        logger.logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)
        return logger
    }()

    let factory = PrometheusMetricsFactory()
    MetricsSystem.bootstrap(factory)
    let systemMetricsMonitor = SystemMetricsMonitor(
        configuration: SystemMetricsMonitor.Configuration(pollInterval: .milliseconds(50)),
        logger: logger,
    )

    let router = try buildRouter(logger: logger)
    let app = Application(
        router: router,
        configuration: ApplicationConfiguration(reader: reader.scoped(to: "http")),
        services: [systemMetricsMonitor],
        logger: logger
    )
    return app
}
