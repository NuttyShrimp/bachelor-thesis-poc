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
            VatCalculation(dataLoader: dataLoader, logger: logger),
            CartCalculation(dataLoader: dataLoader, logger: logger),
            ExcelGeneration(dataLoader: dataLoader, logger: logger),
        ]
    }

    func getAvailableOperations() -> [BenchmarkOperationDescription] {
        return operations.map { $0.description() }
    }

    func runOperation(for operation: String) async throws -> [String: ScenarioResult] {
        let runner = try createOperation(for: operation)

        logger.info("Running benchmark operation: \(operation)")

        return runner.run()
    }

    private func createOperation(for name: String) throws -> any BenchmarkOperation {
        switch name {
        case "dto_mapping":
            return DtoMapping(dataLoader: dataLoader, logger: logger)
        case "json_transformation":
            return JsonTransformation(dataLoader: dataLoader, logger: logger)
        case "cart_calculation":
            return CartCalculation(dataLoader: dataLoader, logger: logger)
        case "vat_calculation":
            return VatCalculation(dataLoader: dataLoader, logger: logger)
        case "excel_generation":
            return ExcelGeneration(dataLoader: dataLoader, logger: logger)
        default:
            throw BenchmarkError.UnknownOperation(name: name)
        }
    }
}
