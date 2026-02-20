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
    public var available: Bool = false
    public var availableOperations: [String: [String]?] = [:]

    public init(endpoint: String) {
        self.endpoint = endpoint
        self.httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func updateEndpoint(with newEndpoint: String) throws {
        guard !isBusy else {
            throw WorkerError.AlreadyBusy
        }
        endpoint = newEndpoint
        if endpoint.hasSuffix("/") {
            endpoint.removeLast()
        }
    }

    public func checkAvailability() async throws -> Bool {
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

    public func loadAvailableOperations() async throws {
        guard !isBusy else {
            throw WorkerError.AlreadyBusy
        }
        isBusy = true
        defer { isBusy = false }

        do {
            let request = HTTPClientRequest(url: "\(endpoint)/api/benchmarks")
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            guard response.status == .ok else { return }
            let body = try await response.body.collect(upTo: 2 * 1024 * 1024)
            let result = try self.decoder.decode(OperationsResult.self, from: body)
            for operation in result.operations {
                availableOperations[operation.name] = operation.scenarios
            }
        } catch {
            throw WorkerError.RequestError(error)
        }
    }

    /// Run a specific benchmark operation (optionally filtered by scenario).
    /// Pass `operation: "all"` to run all benchmarks via POST /api/benchmarks/run-all.
    public func runBenchmark(operation: String, scenario: String?) async throws -> Result<
        TestResult, WorkerError
    > {
        guard !isBusy else {
            throw WorkerError.AlreadyBusy
        }

        if operation != "all" {
            guard availableOperations.keys.contains(operation) else {
                return .failure(WorkerError.InvalidOperation(operation, nil))
            }
            if let scenario = scenario,
                let knownScenarios = availableOperations[operation],
                let scenarios = knownScenarios,
                !scenarios.contains(scenario)
            {
                return .failure(WorkerError.InvalidOperation(operation, scenario))
            }
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let url: String
            if operation == "all" {
                url = "\(endpoint)/api/benchmarks/run-all"
            } else if let scenario = scenario {
                url = "\(endpoint)/api/benchmarks/run/\(operation)?scenario=\(scenario)"
            } else {
                url = "\(endpoint)/api/benchmarks/run/\(operation)"
            }

            var request = HTTPClientRequest(url: url)
            if operation == "all" {
                request.method = .POST
                request.headers.add(name: "Content-Type", value: "application/json")
                let bodyData = Data("{}".utf8)
                request.body = .bytes(bodyData)
            }

            let response = try await httpClient.execute(request, timeout: .seconds(600))
            guard response.status == .ok else {
                return .failure(WorkerError.FailedHTTPRequest(response))
            }
            let body = try await response.body.collect(upTo: 10 * 1024 * 1024)
            let result = try self.decoder.decode(TestResult.self, from: body)
            return .success(result)
        } catch let error as WorkerError {
            throw error
        } catch {
            throw WorkerError.RequestError(error)
        }
    }

    func destroy() async throws {
        try await self.httpClient.shutdown()
    }
}
