import AsyncHTTPClient
import Logging
import Synchronization

public actor Workers {
    private let logger: Logger
    let swift: EndpointService
    let php: EndpointService
    let octane: EndpointService

    init(settings: JobSettings, logger: Logger) {
        swift = EndpointService(endpoint: settings.swiftEndpoint)
        php = EndpointService(endpoint: settings.phpEndpoint)
        octane = EndpointService(endpoint: settings.octaneEndpoint)
        self.logger = logger
    }

    private func updateService(name: String, service: EndpointService, endpoint: String) {
        do {
            try service.updateEndpoint(with: endpoint)
        } catch WorkerError.AlreadyBusy {
            logger.error(
                "Cannot update service endpoint while busy", metadata: ["service": .string(name)])
        } catch WorkerError.RequestError(let e) {
            logger.error(
                "Failed to update swift endpoint",
                metadata: ["error": "\(e)", "service": .string(name)])
        } catch {
            logger.error(
                "Unexpected error thrown while updating endpoint",
                metadata: ["service": .string(name), "error": "\(error)"])
        }
    }

    func applySettings(_ settings: JobSettings) {
        updateService(name: "swift", service: swift, endpoint: settings.swiftEndpoint)
        updateService(name: "php", service: php, endpoint: settings.phpEndpoint)
        updateService(name: "octane", service: octane, endpoint: settings.octaneEndpoint)
    }

    func shutdown() async throws {
        try await swift.destroy()
        try await php.destroy()
        try await octane.destroy()
    }
}

public final class EndpointService: @unchecked Sendable {
    private let httpClient: HTTPClient
    private var endpoint: String
    private var isBusy: Bool = false
    var available: Bool = false
    var availableOperations: [String: [String]] = [:]

    init(endpoint: String) {
        self.endpoint = endpoint
        self.httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
    }

    func updateEndpoint(with: String) throws {
        guard !isBusy else {
            throw WorkerError.AlreadyBusy
        }
        endpoint = with
        if endpoint.hasSuffix("/") {
            endpoint.removeLast()
        }
    }

    func checkAvailability() async throws -> Bool {
        guard !isBusy else {
            throw WorkerError.AlreadyBusy
        }
        isBusy = true
        defer { isBusy = false }

        do {
            let request = HTTPClientRequest(url: "\(endpoint)/health")
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            available = response.status == .ok
            return available

        } catch {
            throw WorkerError.RequestError(error)
        }
    }

    func destroy() async throws {
        try await self.httpClient.shutdown()
    }
}
