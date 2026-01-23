public enum JobType: Codable, Sendable {
    case Swift, PHP, PHPOctane
}

public struct JobSettings: Codable, Sendable {
    public let swiftEndpoint: String
    public let phpEndpoint: String
    public let octaneEndpoint: String
    init() {
        swiftEndpoint = "http://localhost:3000"
        phpEndpoint = "http://localhost:8000"
        octaneEndpoint = "http://localhost:8001"
    }
}

public struct JobInfo<T: Codable & Sendable>: Codable, Sendable {
    public let swift: T
    public let php: T
    public let octane: T
}
