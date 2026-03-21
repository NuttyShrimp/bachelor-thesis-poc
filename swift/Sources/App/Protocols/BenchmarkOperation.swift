protocol BenchmarkOperation: Sendable {
    func description() -> BenchmarkOperationDescription
    func run() -> [String: ScenarioResult]
}
