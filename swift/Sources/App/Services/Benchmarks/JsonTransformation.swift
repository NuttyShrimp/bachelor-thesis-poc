import Foundation
import Hummingbird
import Logging

struct JsonTransformation: BenchmarkOperation {
    let iterations = 100
    let dataLoader: DataLoader
    let logger: Logger
    let decoder = createDecoder()
    let encoder = createEncoder()

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

    func run() async -> [String: ScenarioResult] {
        return [
            "json_transformation": benchmark()
        ]
    }

    func benchmark() -> ScenarioResult {
        let data = dataLoader.shopData()
        // Warmup
        do {
            let result = try decoder.decode(Shop.self, from: data)
            _ = try encoder.encode(result)
        } catch {
            logger.error("Failed to run json transformation warmup: \(error)")
        }

        var times: [Double] = []
        var transformedCount = 0

        let memoryUsageStart = reportMemory()
        let startTime = Int(Date.now.timeIntervalSince1970)

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

    func single(scenario: String) async throws -> BenchmarkSingleResult {
        let data = dataLoader.shopData()
        // Do not share locks between instances
        #if ReerJSON
            let decoder = createDecoder()
            let encoder = createEncoder()
        #endif
        do {
            let result = try decoder.decode(Shop.self, from: data)
            _ = try encoder.encode(result)
            return .json(AnyEncodable(result))
        } catch {
            logger.error("JSON transformation failed: \(error)")
            throw BenchmarkError.DecoderError(err: error)
        }
    }

}
