import Hummingbird

struct ScenarioResult: ResponseEncodable {
    let operation: String

    let orderCount: Double
    let iterations: Double

    let avgTimeMs: Double
    let minTimeMs: Double
    let maxTimeMs: Double

    let stdDevMs: Double
    let p50TimeMs: Double
    let p95TimeMs: Double
    let p99TimeMs: Double

    let memoryUsedMd: Double
    let avgTimePerOrderMs: Double

    let totalTimeMs: Double
}
