import Hummingbird

protocol BenchmarkOperation: Sendable {
    func description() -> BenchmarkOperationDescription
    func run() async -> [String: ScenarioResult]
    func single(scenario: String) async throws -> Encodable
}
