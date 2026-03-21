import Foundation
import Hummingbird

// HTTP models
struct BenchmarkOptionsResponse: ResponseEncodable {
    let operations: [BenchmarkOperationDescription]
    let meta: BenchmarkMeta
}

struct BenchmarkRunResponse: ResponseEncodable {
    // Operation to Scenario to Result
    let benchmarks: [String: [String: ScenarioResult]]
    let meta: BenchmarkMeta
}

struct BenchmarkOperationDescription: ResponseEncodable {
    let name: String
    let complexity: String
    let scenarios: [String]
}

struct BenchmarkMeta: ResponseEncodable {
    let timestamp: Date
    let runtime: String
}

func CreateMeta() -> BenchmarkMeta {
    BenchmarkMeta(timestamp: .now, runtime: "swift")
}
