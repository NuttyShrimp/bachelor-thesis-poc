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
        return [
            "product_settings": benchmarkProductSettings(),
            "order_settings": benchmarkOrderSettings(),
            "order_products": benchmarkOrderProducts(),
            "full_order": benchmarkFullOrder(),
        ]
    }

    func benchmarkProductSettings() -> ScenarioResult {
        let products = dataLoader.productSettingsData()
        var times: [Double] = []
        var mappedCount = 0
        var failedCount = 0

        let memoryUsageStart = reportMemory()
        let decoder = createDecoder()

        for _ in 0..<iterations {
            let startTime = Date()

            for settings in products {
                do {
                    _ = try decoder.decode(ProductSettings.self, from: settings)
                    mappedCount += 1
                } catch {
                    failedCount += 1
                    logger.error("Failed to decode: \(error)")
                }
            }
            let stopTime = Date()
            let elapsedTime = stopTime.timeIntervalSince(startTime) * 1000
            logger.debug("Iteration completed in \(elapsedTime) ms")
            times.append(elapsedTime)
        }

        let memoryUsageEnd = reportMemory()
        logger.debug(
            "Mapped \(mappedCount) product settings. Memory used: \(memoryUsageEnd - memoryUsageStart) MB, Start: \(memoryUsageStart) MB, End: \(memoryUsageEnd) MB"
        )
        if failedCount > 0 {
            logger.warning("Failed to decode \(failedCount) ProductSettings payloads")
        }

        return ScenarioResult.create(
            for: "dto_mapping_product_settings",
            orderCount: products.count,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart
        )
    }

    func benchmarkOrderSettings() -> ScenarioResult {
        let orders = dataLoader.orderSettingsData()
        var times: [Double] = []
        var mappedCount = 0
        var failedCount = 0

        let memoryUsageStart = reportMemory()
        let decoder = createDecoder()

        for _ in 0..<iterations {
            let startTime = Date()

            for settings in orders {
                do {
                    _ = try decoder.decode(OrderSettings.self, from: settings)
                    mappedCount += 1
                } catch {
                    failedCount += 1
                    logger.error("Failed to decode: \(error)")
                }
            }
            let stopTime = Date()
            let elapsedTime = stopTime.timeIntervalSince(startTime) * 1000
            logger.debug("Iteration completed in \(elapsedTime) ms")
            times.append(elapsedTime)
        }

        let memoryUsageEnd = reportMemory()
        logger.debug(
            "Mapped \(mappedCount) order settings. Memory used: \(memoryUsageEnd - memoryUsageStart) MB, Start: \(memoryUsageStart) MB, End: \(memoryUsageEnd) MB"
        )
        if failedCount > 0 {
            logger.warning("Failed to decode \(failedCount) OrderSettings payloads")
        }

        return ScenarioResult.create(
            for: "dto_mapping_order_settings",
            orderCount: orders.count,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart
        )
    }

    func benchmarkOrderProducts() -> ScenarioResult {
        let orders = dataLoader.orderProductsData()
        var times: [Double] = []
        var mappedCount = 0
        var failedCount = 0

        let memoryUsageStart = reportMemory()
        let decoder = createDecoder()

        for _ in 0..<iterations {
            let startTime = Date()

            for products in orders {
                do {
                    _ = try decoder.decode([OrderProduct].self, from: products)
                    mappedCount += 1
                } catch {
                    failedCount += 1
                    logger.error("Failed to decode: \(error)")
                }
            }
            let stopTime = Date()
            let elapsedTime = stopTime.timeIntervalSince(startTime) * 1000
            logger.debug("Iteration completed in \(elapsedTime) ms")
            times.append(elapsedTime)
        }

        let memoryUsageEnd = reportMemory()
        logger.debug(
            "Mapped \(mappedCount) order products. Memory used: \(memoryUsageEnd - memoryUsageStart) MB, Start: \(memoryUsageStart) MB, End: \(memoryUsageEnd) MB"
        )
        if failedCount > 0 {
            logger.warning("Failed to decode \(failedCount) OrderProducts payloads")
        }

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
        var mappedCount = 0
        var failedCount = 0

        let memoryUsageStart = reportMemory()
        let decoder = createDecoder()

        for _ in 0..<iterations {
            let startTime = Date()

            for fullOrder in orders {
                do {
                    _ = try decoder.decode(FullOrder.self, from: fullOrder)
                    mappedCount += 1
                } catch {
                    failedCount += 1
                    logger.error("Failed to decode: \(error)")
                }
            }
            let stopTime = Date()
            let elapsedTime = stopTime.timeIntervalSince(startTime) * 1000
            logger.debug("Iteration completed in \(elapsedTime) ms")
            times.append(elapsedTime)
        }

        let memoryUsageEnd = reportMemory()
        logger.debug(
            "Mapped \(mappedCount) full orders. Memory used: \(memoryUsageEnd - memoryUsageStart) MB, Start: \(memoryUsageStart) MB, End: \(memoryUsageEnd) MB"
        )
        if failedCount > 0 {
            logger.warning("Failed to decode \(failedCount) FullOrder payloads")
        }

        return ScenarioResult.create(
            for: "dto_mapping_full_order",
            orderCount: orders.count,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart
        )

    }
}
