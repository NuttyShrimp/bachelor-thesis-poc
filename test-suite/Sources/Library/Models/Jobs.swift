import Observation

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

    func getForType(type: JobType) -> String {
        switch type {
        case .Swift: return self.swiftEndpoint
        case .PHP: return self.phpEndpoint
        case .PHPOctane: return self.octaneEndpoint
        }
    }
}

public struct WorkerInfo<T: Codable & Sendable>: Codable, Sendable {
    public let swift: T
    public let php: T
    public let octane: T

    func getForType(type: JobType) -> T {
        switch type {
        case .Swift: return self.swift
        case .PHP: return self.php
        case .PHPOctane: return self.octane
        }
    }
}
