import Foundation
import Logging

struct DtoMapping: BenchmarkOperation {
    let iterations = 50
    let dataLoader: DataLoader
    let logger: Logger
    let decoder: JSONDecoder

    init(dataLoader: DataLoader, logger: Logger) {
        self.dataLoader = dataLoader
        self.logger = logger
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func description() -> BenchmarkOperationDescription {
        return BenchmarkOperationDescription(
            name: "dto_mapping",
            complexity: "O(1)",
            scenarios: [
                "product_settings",
                "order_settings",
                "order_products",
                "full_order",
            ]
        )
    }

    func run() -> [String: ScenarioResult] {
        var resultMap = [String: ScenarioResult]()

        resultMap["product_settings"] = benchmarkProductSettings()

        return resultMap
    }

    func benchmarkProductSettings() -> ScenarioResult {
        let products = dataLoader.productsMap()
        var times: [Double] = []
        var mappedSettings: [ProductSettings] = []

        let memoryUsageStart = reportMemory()

        // Extract settings_json key & map to model
        for _ in 0..<iterations {
            let startTime = Date()

            for product in products {
                // NOTE: we can move this operation to a seperate thread
                if let productDict = product as? [String: Any],
                    let settingsJson = productDict["settings_json"] as? String,
                    let settingsData = settingsJson.data(using: .utf8)
                {
                    do {
                        let mapped = try decoder.decode(ProductSettings.self, from: settingsData)
                        mappedSettings.append(mapped)
                    } catch {
                        logger.error("Failed to decode ProductSettings: \(error)")
                    }
                }
            }
            let stopTime = Date()
            let elapsedTime = stopTime.timeIntervalSince(startTime) * 1000
            logger.debug("Iteration completed in \(elapsedTime) ms")
            times.append(elapsedTime)
        }

        let memoryUsageEnd = reportMemory()
        logger.debug(
            "Mapped \(mappedSettings.count) product settings. Memory used: \(memoryUsageEnd - memoryUsageStart) MB, Start: \(memoryUsageStart) MB, End: \(memoryUsageEnd) MB"
        )

        return ScenarioResult.create(
            for: "dto_mapping_product_settings",
            orderCount: products.count,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart
        )
    }
}
