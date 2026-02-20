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
    private let workerAvailabilty: ObservableState<WorkerInfo<Bool>>
    private let workerOperations: ObservableState<WorkerInfo<[String: [String]]>>

    public private(set) var settings = JobSettings()
    public var availability: WorkerInfo<Bool> {
        workerAvailabilty.item
    }
    public var operations: WorkerInfo<[String: [String]]> {
        workerOperations.item
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
        workerOperations = ObservableState(
            item: .init(
                swift: workers.services[.Swift]!.availableOperations,
                php: workers.services[.PHP]!.availableOperations,
                octane: workers.services[.PHPOctane]!.availableOperations
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

    public func getAvailabilityObservation() async -> Observations<WorkerInfo<Bool>, Never> {
        Observations { self.workerAvailabilty.item }
    }

    public func getOperationsObservation() async -> Observations<
        WorkerInfo<[String: [String]]>, Never
    > {
        Observations { self.workerOperations.item }
    }

    public func runBenchmark(
        _ operation: String, scenario: String?, jobTypes: [JobType]?
    ) async -> [JobType: TestResult] {
        if jobTypes != nil {
            return await workers.runBenchmark(operation, scenario: scenario, for: jobTypes!)
        }
        return await workers.runBenchmark(operation, scenario: scenario)
    }
}
