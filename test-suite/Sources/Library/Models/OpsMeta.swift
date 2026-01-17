struct TestResult {
    let operations: [Operation]
    let meta: Meta
}

struct Operation {
    let name: String
    let description: String
    let complexity: String
}

struct Meta {}
