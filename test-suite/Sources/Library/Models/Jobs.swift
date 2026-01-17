public enum JobType: Codable, Sendable {
    case Swift, PHP, PHPOctane
}

public struct JobSettings: Codable, Sendable {
    public var swiftEndpoint: String
    public var phpEndpoint: String
    public var octaneEndpoint: String
    init() {
        swiftEndpoint = "http://localhost:3000"
        phpEndpoint = "http://localhost:8000"
        octaneEndpoint = "http://localhost:8001"
    }
}
