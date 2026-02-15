import AsyncHTTPClient
import Foundation
import Logging
import Observation
import Synchronization

@Observable
public final class EndpointService: @unchecked Sendable {
    private let httpClient: HTTPClient
    private var endpoint: String
    private var isBusy: Bool = false
    private var decoder = JSONDecoder()
    var available: Bool = false
    var availableOperations: [String: [String]] = [:]

    init(endpoint: String) {
        self.endpoint = endpoint
        self.httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        self.decoder.dateDecodingStrategy = .iso8601
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
            let request = HTTPClientRequest(url: "\(endpoint)/api/health")
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            available = response.status == .ok
            return available

        } catch {
            available = false
            throw WorkerError.RequestError(error)
        }
    }

    func loadAvailableOperations() async throws {
        guard !isBusy else {
            throw WorkerError.AlreadyBusy
        }
        isBusy = true
        defer { isBusy = false }

        do {
            let request = HTTPClientRequest(url: "\(endpoint)/api/benchmarks")
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            guard response.status == .ok else {
                return
            }
            let body = try await response.body.collect(upTo: 1024 * 1024)
            let result = try self.decoder.decode(OperationsResult.self, from: body)
            for operation in result.operations {
                availableOperations[operation.name] = operation.scenarios
            }
        } catch {
            throw WorkerError.RequestError(error)
        }
    }

    func runBenchmark(operation: String, scenario: String?) async throws -> Result<
        TestResult, WorkerError
    > {
        guard !isBusy else {
            throw WorkerError.AlreadyBusy
        }
        isBusy = true
        defer { isBusy = false }

        guard availableOperations.keys.contains(operation) else {
            return .failure(WorkerError.InvalidOperation(operation, nil))
        }
        guard scenario == nil || availableOperations[operation]!.contains(scenario!) else {
            return .failure(WorkerError.InvalidOperation(operation, scenario))
        }

        do {
            let request = HTTPClientRequest(url: "\(endpoint)/api/benchmarks/run/\(operation)")
            // TODO: add scenario query
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            guard response.status == .ok else {
                return .failure(WorkerError.FailedHTTPRequest(response))
            }
            let body = try await response.body.collect(upTo: 1024 * 1024)
            let result = try self.decoder.decode(TestResult.self, from: body)
            // TODO: Cache
            return .success(result)
        } catch {
            throw WorkerError.RequestError(error)
        }
    }

    func destroy() async throws {
        try await self.httpClient.shutdown()
    }
}
