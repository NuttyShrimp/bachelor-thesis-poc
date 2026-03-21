final class BenchmarkService: Sendable {
    let operations: [BenchmarkOperation] = []

    func getAvailableOperations() -> [BenchmarkOperationDescription] {
        return operations.map { $0.description() }
    }

    func runOperation(for operation: String) async throws -> [String: ScenarioResult] {
        let runner = operations.first { $0.description().name == operation }
        if runner == nil {
            throw BenchmarkError.UnknownOperation(name: operation)
        }

        return runner!.run()
    }
}
