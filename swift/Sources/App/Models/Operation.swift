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
        let sortedTimes = times.sorted()
        return ScenarioResult(
            operation: name,
            orderCount: orderCount,
            iterations: iterations,
            avgTimeMs: times.reduce(0, +) / Double(times.count),
            minTimeMs: times.min() ?? 0,
            maxTimeMs: times.max() ?? 0,
            stdDevMs: Math.stdDev(times),
            p50TimeMs: sortedTimes[Int(Double(sortedTimes.count) * 0.5)],
            p95TimeMs: sortedTimes[Int(Double(sortedTimes.count) * 0.95)],
            p99TimeMs: sortedTimes[Int(Double(sortedTimes.count) * 0.99)],
            memoryUsedMb: memoryUsage,
            avgTimePerOrderMs: times.reduce(0, +) / Double(orderCount * iterations),
            totalTimeMs: times.reduce(0, +),
        )
    }
}
