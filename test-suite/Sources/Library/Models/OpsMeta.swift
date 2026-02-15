struct OperationsResult: Codable {
    let operations: [Operation]
    let meta: Meta
}

public struct TestResult: Codable, Sendable {
    let benchmarks: [Operation]
    let meta: Meta
}

public struct Operation: Codable, Sendable {
    let name: String
    let description: String
    let complexity: String
    let scenarios: [String]
}

public struct Meta: Codable, Sendable {}
