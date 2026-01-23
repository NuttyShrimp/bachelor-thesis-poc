import Jobs
import Logging
import ServiceLifecycle

public actor JobService: Service {
    struct PerfParameters: JobParameters {
        static let jobName = "performance_tests"
        let type: JobType
        let operation: String
        let scenario: String?
    }

    public private(set) var settings = JobSettings()
    private let workers: Workers

    public init(_ queue: some JobQueueProtocol, logger: Logger) {
        workers = Workers(settings: settings, logger: logger)

        queue.registerJob(parameters: PerfParameters.self) { parameters, ctx in
            print("New job for \(parameters.type)")
        }
    }

    // This is from the Service protocol
    public func run() async throws {
        try? await gracefulShutdown()
        try await self.workers.shutdown()
    }

    public func modifySettings(_ newSettings: JobSettings) async {
        settings = newSettings
        await workers.applySettings(newSettings)
    }

    public func getAvailability() async -> JobInfo<Bool> {
        return JobInfo<Bool>(
            swift: workers.swift.available,
            php: workers.php.available,
            octane: workers.octane.available,
        )
    }
}
