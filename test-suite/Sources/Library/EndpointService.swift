import AsyncHTTPClient
import Logging
import Observation
import Synchronization

@Observable
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
            available = false
            throw WorkerError.RequestError(error)
        }
    }

    func destroy() async throws {
        try await self.httpClient.shutdown()
    }
}
