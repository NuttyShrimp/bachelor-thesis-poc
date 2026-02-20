struct OperationsResult: Codable {
    let operations: [OperationInfo]
    let meta: Meta
}

/// Describes a single benchmark operation as returned by GET /api/benchmarks
public struct OperationInfo: Codable, Sendable {
    public let name: String
    public let complexity: String
    public let scenarios: [String]?
}

/// A single scenario result as returned by the benchmark runner (spec.md)
public struct BenchmarkResult: Codable, Sendable {
    public let operation: String?
    public let orderCount: Int?
    public let iterations: Int?
    public let avgTimeMs: Double
    public let minTimeMs: Double
    public let maxTimeMs: Double
    public let stdDevMs: Double
    public let p50TimeMs: Double
    public let p95TimeMs: Double
    public let p99TimeMs: Double
    public let memoryUsedMb: Double
    public let avgTimePerOrderMs: Double?
    public let totalTimeMs: Double?

    enum CodingKeys: String, CodingKey {
        case operation
        case orderCount = "order_count"
        case iterations
        case avgTimeMs = "avg_time_ms"
        case minTimeMs = "min_time_ms"
        case maxTimeMs = "max_time_ms"
        case stdDevMs = "std_dev_ms"
        case p50TimeMs = "p50_time_ms"
        case p95TimeMs = "p95_time_ms"
        case p99TimeMs = "p99_time_ms"
        case memoryUsedMb = "memory_used_mb"
        case avgTimePerOrderMs = "avg_time_per_order_ms"
        case totalTimeMs = "total_time_ms"
    }
}

/// Response from GET /api/benchmarks/run/{operation}
/// benchmarks is a dict of operation -> (scenario -> BenchmarkResult)
public struct TestResult: Codable, Sendable {
    public let benchmarks: [String: AnyCodable]
    public let meta: Meta
}

/// Metadata block returned alongside benchmark results
public struct Meta: Codable, Sendable {
    public let timestamp: String?
    public let runtime: String?
    public let phpVersion: String?
    public let laravelVersion: String?
    public let runtimeMode: String?
    public let os: String?
    public let architecture: String?
    public let memoryLimit: String?
    public let opcacheEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case timestamp, runtime, os, architecture
        case phpVersion = "php_version"
        case laravelVersion = "laravel_version"
        case runtimeMode = "runtime_mode"
        case memoryLimit = "memory_limit"
        case opcacheEnabled = "opcache_enabled"
    }
}

/// Type-erased Codable value for flexible benchmark result decoding
public enum AnyCodable: Codable, Sendable {
    case benchmarkResult(BenchmarkResult)
    case scenarioMap([String: BenchmarkResult])
    case unknown

    public init(from decoder: Decoder) throws {
        // Try dict first (scenario map), then single result
        if let dict = try? decoder.singleValueContainer().decode([String: BenchmarkResult].self) {
            self = .scenarioMap(dict)
        } else if let result = try? decoder.singleValueContainer().decode(BenchmarkResult.self) {
            self = .benchmarkResult(result)
        } else {
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .benchmarkResult(let r): try container.encode(r)
        case .scenarioMap(let m): try container.encode(m)
        case .unknown: try container.encodeNil()
        }
    }

    /// Flatten to a list of (scenarioName, BenchmarkResult) pairs
    public func flatResults(operationName: String) -> [(scenario: String, result: BenchmarkResult)] {
        switch self {
        case .benchmarkResult(let r):
            return [(scenario: operationName, result: r)]
        case .scenarioMap(let m):
            return m.map { (scenario: $0.key, result: $0.value) }.sorted { $0.scenario < $1.scenario }
        case .unknown:
            return []
        }
    }
}
