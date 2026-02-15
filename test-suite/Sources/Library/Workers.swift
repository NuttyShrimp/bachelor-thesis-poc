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

    func applySettings(_ settings: JobSettings) async {
        for (type, service) in services {
            do {
                try service.updateEndpoint(with: settings.getForType(type: type))
                try await service.loadAvailableOperations()
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

    func runBenchmark(
        _ operation: String, scenario: String?, for workers: [JobType] = [.Swift, .PHP, .PHPOctane]
    ) async -> [JobType: TestResult] {
        var results: [JobType: TestResult] = [:]
        for (type, service) in services {
            if !workers.contains(type) {
                continue
            }

            do {
                let result =
                    try (await service.runBenchmark(operation: operation, scenario: scenario))
                    .get()
                results[type] = result
            } catch WorkerError.AlreadyBusy {
                logger.error(
                    "Cannot run benchmark for service while already busy",
                    metadata: [
                        "service": "\(type)", "operation": .string(operation),
                    ])
                continue
            } catch WorkerError.RequestError(let e) {
                logger.warning(
                    "Failed to contact benchmark endpoint in service",
                    metadata: ["error": "\(e)", "service": "\(type)"])
            } catch WorkerError.InvalidOperation(let op, let sc) {
                logger.warning(
                    "Tried running unknown operation and/or scenarion for service",
                    metadata: [
                        "service": "\(type)", "operation": .string(op),
                        "scenario": .string(sc ?? "all"),
                    ])
            } catch WorkerError.FailedHTTPRequest(let resp) {
                logger.warning(
                    "benchmark request failed for service",
                    metadata: [
                        "service": "\(type)", "HTTPStatus": "\(resp.status.description)",
                    ])
            } catch {
                logger.error(
                    "Unexpected error thrown while running benchmark for service",
                    metadata: ["service": "\(type)", "error": "\(error)"])
            }
        }
        return results
    }

    func shutdown() async throws {
        for (_, service) in services {
            try await service.destroy()
        }
    }
}
