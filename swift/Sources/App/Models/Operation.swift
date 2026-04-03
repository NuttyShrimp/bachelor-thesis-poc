import Hummingbird

struct ScenarioResult: ResponseEncodable {
    let operation: String

    let orderCount: Int
    let iterations: Int

    let avgTimeMs: Double
    let minTimeMs: Double
    let maxTimeMs: Double

    let stdDevMs: Double
    let p50TimeMs: Double
    let p95TimeMs: Double
    let p99TimeMs: Double

    let memoryUsedMb: Double
    let avgTimePerOrderMs: Double

    let totalTimeMs: Double
}

extension ScenarioResult {
    static func create(for name: String, orderCount: Int, iterations: Int, times: [Double], memoryUsage: Double) -> ScenarioResult {
        let safeOrderCount = max(orderCount, 0)
        let safeIterations = max(iterations, 0)
        let safeDenominator = safeOrderCount * safeIterations

        let totalTime = times.reduce(0, +)
        let averageTime = times.isEmpty ? 0 : totalTime / Double(times.count)
        let sortedTimes = times.sorted()

        func percentile(_ value: Double) -> Double {
            guard !sortedTimes.isEmpty else { return 0 }
            let rawIndex = Int(Double(sortedTimes.count - 1) * value)
            let clampedIndex = max(0, min(rawIndex, sortedTimes.count - 1))
            return sortedTimes[clampedIndex]
        }

        return ScenarioResult(
            operation: name,
            orderCount: safeOrderCount,
            iterations: safeIterations,
            avgTimeMs: averageTime,
            minTimeMs: times.min() ?? 0,
            maxTimeMs: times.max() ?? 0,
            stdDevMs: times.isEmpty ? 0 : Math.stdDev(times),
            p50TimeMs: percentile(0.50),
            p95TimeMs: percentile(0.95),
            p99TimeMs: percentile(0.99),
            memoryUsedMb: memoryUsage,
            avgTimePerOrderMs: safeDenominator > 0 ? totalTime / Double(safeDenominator) : 0,
            totalTimeMs: totalTime,
        )
    }
}
