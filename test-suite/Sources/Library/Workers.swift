import Logging

public actor Workers {
    private let logger: Logger
    let services: [JobType: EndpointService]

    init(settings: JobSettings, logger: Logger) {
        services = [
            .Swift: EndpointService(endpoint: settings.swiftEndpoint),
            .PHP: EndpointService(endpoint: settings.phpEndpoint),
            .PHPOctane: EndpointService(endpoint: settings.octaneEndpoint),
        ]
        self.logger = logger
    }

    func applySettings(_ settings: JobSettings) {
        for (type, service) in services {
            do {
                try service.updateEndpoint(with: settings.getForType(type: type))
            } catch WorkerError.AlreadyBusy {
                logger.error(
                    "Cannot update service endpoint while busy",
                    metadata: ["service": "\(type)"])
            } catch {
                logger.error(
                    "Unexpected error thrown while updating endpoint",
                    metadata: ["service": "\(type)", "error": "\(error)"])
            }
        }
    }

    func checkAvailability() async {
        for (type, service) in services {
            do {
                _ = try await service.checkAvailability()
            } catch WorkerError.AlreadyBusy {
                logger.error(
                    "Cannot check availability of service while busy",
                    metadata: ["service": "\(type)"])
            } catch WorkerError.RequestError(let e) {
                logger.warning(
                    "Failed to contact health endpoint in service",
                    metadata: ["error": "\(e)", "service": "\(type)"])
            } catch {
                logger.error(
                    "Unexpected error thrown checking availability for service",
                    metadata: ["service": "\(type)", "error": "\(error)"])
            }
        }

    }

    func shutdown() async throws {
        for (_, service) in services {
            try await service.destroy()
        }
    }
}
