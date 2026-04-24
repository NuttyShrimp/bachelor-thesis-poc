protocol BenchmarkOperation: Sendable {
    func description() -> BenchmarkOperationDescription
    func run() async -> [String: ScenarioResult]
}
