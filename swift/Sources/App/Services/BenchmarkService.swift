import Logging

final class BenchmarkService: Sendable {
    let dataLoader: DataLoader
    let logger: Logger
    let operations: [BenchmarkOperation]

    init(logger: Logger) {
        self.logger = logger
        self.dataLoader = DataLoader(logger: logger)
        self.operations = [
            DtoMapping(dataLoader: dataLoader, logger: logger),
            JsonTransformation(dataLoader: dataLoader, logger: logger),
        ]
    }

    func getAvailableOperations() -> [BenchmarkOperationDescription] {
        return operations.map { $0.description() }
    }

    func runOperation(for operation: String) async throws -> [String: ScenarioResult] {
        let runner = operations.first { $0.description().name == operation }
        if runner == nil {
            throw BenchmarkError.UnknownOperation(name: operation)
        }
        
        logger.info("Running benchmark operation: \(operation)")

        return runner!.run()
    }
}
