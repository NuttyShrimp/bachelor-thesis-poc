import Foundation
import Logging

struct JsonTransformation: BenchmarkOperation {
    let iterations = 100
    let dataLoader: DataLoader
    let logger: Logger

    init(dataLoader: DataLoader, logger: Logger) {
        self.dataLoader = dataLoader
        self.logger = logger
    }

    func description() -> BenchmarkOperationDescription {
        return BenchmarkOperationDescription(
            name: "json_transformation",
            complexity: "O(1)",
            scenarios: []
        )
    }

    func run() -> [String: ScenarioResult] {
        return [
            "json_transformation": benchmark()
        ]
    }

    func benchmark() -> ScenarioResult {
        let data = dataLoader.shopData()
        var times: [Double] = []
        var transformedCount = 0

        let memoryUsageStart = reportMemory()
        let startTime = Int(Date.now.timeIntervalSince1970)
        let decoder = createDecoder()
        let encoder = createEncoder()

        for _ in 0..<iterations {
            let startTime = Date()

            do {
                let result = try decoder.decode(Shop.self, from: data)
                _ = try encoder.encode(result)
                transformedCount += 1
            } catch {
                logger.error("Failed to decode & encode shop data: \(error)")
                continue
            }

            let stopTime = Date()
            let elapsedTime = stopTime.timeIntervalSince(startTime) * 1000
            logger.debug("Iteration completed in \(elapsedTime) ms")
            times.append(elapsedTime)
        }

        let endTime = Int(Date.now.timeIntervalSince1970)
        let memoryUsageEnd = reportMemory()

        return ScenarioResult.create(

            for: "json_transformation",
            orderCount: transformedCount,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart,
            startTime: startTime,
            endTime: endTime
        )
    }

}
