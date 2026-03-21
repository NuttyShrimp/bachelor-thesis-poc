import Configuration
import Hummingbird
import Logging
import OTel

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter reader: configuration reader
func buildApplication(reader: ConfigReader) async throws -> some ApplicationProtocol {
    let logger = {
        var logger = Logger(label: "bap")
        logger.logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)
        return logger
    }()

    var otelConfig = OTel.Configuration.default
    otelConfig.serviceName = "Bap"
    otelConfig.logs.enabled = false
    let observability = try OTel.bootstrap(configuration: otelConfig)

    let router = try buildRouter()
    let app = Application(
        router: router,
        configuration: ApplicationConfiguration(reader: reader.scoped(to: "http")),
        services: [observability],
        logger: logger
    )
    return app
}
