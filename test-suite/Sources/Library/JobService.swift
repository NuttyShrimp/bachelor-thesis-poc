import Jobs

public actor JobService {
    struct PerfParameters: JobParameters {
        static let jobName = "performance_tests"
        let type: JobType
        let endpoint: String
    }

    public var settings = JobSettings()

    public init(_ queue: some JobQueueProtocol) {
        queue.registerJob(parameters: PerfParameters.self) { parameters, ctx in
            print("New job for \(parameters.type)")
        }
    }

    public func modifySettings(_ newSettings: JobSettings) {
        settings = newSettings
    }
}
