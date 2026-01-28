import Jobs
import Logging
import Observation
import ServiceLifecycle

public actor JobService: Service {
    struct PerfParameters: JobParameters {
        static let jobName = "performance_tests"
        let type: JobType
        let operation: String
        let scenario: String?
    }

    private let workers: Workers
    private let workerAvailabilty: ObservableState<JobInfo<Bool>>
    public private(set) var settings = JobSettings()
    public var availability: JobInfo<Bool> {
        workerAvailabilty.item
    }

    public init(_ queue: some JobQueueProtocol, logger: Logger) {
        workers = Workers(settings: settings, logger: logger)
        workerAvailabilty = ObservableState(
            item: .init(
                swift: workers.services[.Swift]!.available,
                php: workers.services[.PHP]!.available,
                octane: workers.services[.PHPOctane]!.available
            )
        )

        queue.registerJob(parameters: PerfParameters.self) { parameters, ctx in
            print("New job for \(parameters.type)")
        }
    }

    // This is from the Service protocol
    public func run() async throws {
        await checkAvailability()
        try? await gracefulShutdown()
        try await self.workers.shutdown()
    }

    public func modifySettings(_ newSettings: JobSettings) async {
        settings = newSettings
        await workers.applySettings(newSettings)
    }

    public func checkAvailability() async {
        await workers.checkAvailability()
    }

    public func getAvailabilityObservation() async -> Observations<JobInfo<Bool>, Never> {
        Observations { self.workerAvailabilty.item }
    }
}
