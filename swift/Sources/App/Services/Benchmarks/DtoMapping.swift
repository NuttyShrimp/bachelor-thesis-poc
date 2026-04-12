import Foundation
import Logging

struct DtoMapping: BenchmarkOperation {
    let iterations = 50
    let dataLoader: DataLoader
    let logger: Logger

    init(dataLoader: DataLoader, logger: Logger) {
        self.dataLoader = dataLoader
        self.logger = logger
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
        resultMap["order_settings"] = benchmarkOrderSettings()
        resultMap["order_products"] = benchmarkOrderProducts()
        resultMap["full_order"] = benchmarkFullOrder()

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
                // NOTE: we can move this operation to a seperate threads
                if let productDict = product as? [String: Any],
                    let settingsJson = productDict["settings_json"] as? String,
                    let settingsData = settingsJson.data(using: .utf8)
                {
                    do {
                        let decoder = createDecoder()
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

    func benchmarkOrderSettings() -> ScenarioResult {
        let orders = dataLoader.ordersMap()
        var times: [Double] = []
        var mappedSettings: [OrderSettings] = []

        let memoryUsageStart = reportMemory()

        // Extract settings_json key & map to model
        for _ in 0..<iterations {
            let startTime = Date()

            for order in orders {
                // NOTE: we can move this operation to a seperate threads
                if let orderDict = order as? [String: Any],
                    let settingsJson = orderDict["settings_json"] as? String,
                    let settingsData = settingsJson.data(using: .utf8)
                {
                    do {
                        let decoder = createDecoder()
                        let mapped = try decoder.decode(OrderSettings.self, from: settingsData)
                        mappedSettings.append(mapped)
                    } catch {
                        logger.error("Failed to decode OrderSettings: \(error)")
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
            "Mapped \(mappedSettings.count) order settings. Memory used: \(memoryUsageEnd - memoryUsageStart) MB, Start: \(memoryUsageStart) MB, End: \(memoryUsageEnd) MB"
        )

        return ScenarioResult.create(
            for: "dto_mapping_order_settings",
            orderCount: orders.count,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart
        )
    }

    func benchmarkOrderProducts() -> ScenarioResult {
        let orders = dataLoader.ordersMap()
        var times: [Double] = []
        var mappedSettings: [OrderProducts] = []

        let memoryUsageStart = reportMemory()

        // Extract settings_json key & map to model
        for _ in 0..<iterations {
            let startTime = Date()

            for order in orders {
                // NOTE: we can move this operation to a seperate threads
                if let orderDict = order as? [String: Any],
                    let settingsJson = orderDict["products_json"] as? String,
                    let settingsData = settingsJson.data(using: .utf8)
                {
                    do {
                        let decoder = createDecoder()
                        let mapped = try decoder.decode([OrderProduct].self, from: settingsData)
                        mappedSettings.append(mapped)
                    } catch {
                        logger.error("Failed to decode OrderSettings: \(error)")
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
            "Mapped \(mappedSettings.count) order settings. Memory used: \(memoryUsageEnd - memoryUsageStart) MB, Start: \(memoryUsageStart) MB, End: \(memoryUsageEnd) MB"
        )

        return ScenarioResult.create(
            for: "dto_mapping_order_products",
            orderCount: orders.count,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart
        )
    }

    func benchmarkFullOrder() -> ScenarioResult {
        let orders = dataLoader.ordersMap()
        var times: [Double] = []
        var mappedSettings: [FullOrder] = []

        let memoryUsageStart = reportMemory()

        // Extract settings_json key & map to model
        for _ in 0..<iterations {
            let startTime = Date()

            for order in orders {
                if let orderJson = order as? String,
                    let orderData = orderJson.data(using: .utf8)
                {
                    do {
                        let decoder = createDecoder()
                        let mapped = try decoder.decode(FullOrder.self, from: orderData)
                        mappedSettings.append(mapped)
                    } catch {
                        logger.error("Failed to decode OrderSettings: \(error)")
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
            "Mapped \(mappedSettings.count) order settings. Memory used: \(memoryUsageEnd - memoryUsageStart) MB, Start: \(memoryUsageStart) MB, End: \(memoryUsageEnd) MB"
        )

        return ScenarioResult.create(
            for: "dto_mapping_full_order",
            orderCount: orders.count,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart
        )

    }
}
