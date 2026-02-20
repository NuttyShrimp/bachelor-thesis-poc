import Foundation
import Logging
import TestSuiteLibrary

// MARK: - Progress printing helpers (write to stderr so --format json output is clean)

public func printProgress(_ message: String) {
    let standardError = FileHandle.standardError
    message.withCString { ptr in
        _ = Foundation.write(standardError.fileDescriptor, ptr, strlen(ptr))
        _ = Foundation.write(standardError.fileDescriptor, "\n", 1)
    }
}

public func printError(_ message: String) {
    printProgress("error: \(message)")
}

// MARK: - CLI Runner

/// Orchestrates connecting to each app, running benchmarks, and collecting results.
public struct CliRunner: Sendable {
    public let settings: JobSettings

    private let appLabel: @Sendable (JobType) -> String = { type in
        switch type {
        case .Swift:     return "swift"
        case .PHP:       return "php-fpm"
        case .PHPOctane: return "php-octane"
        }
    }

    public init(settings: JobSettings) {
        self.settings = settings
    }

    /// Run benchmarks for the requested workers & operations, returning structured results.
    public func run(
        jobTypes: [JobType],
        operations: [String],   // pass ["all"] to run all available operations
        scenario: String?
    ) async -> RunResults {
        let workers = Workers(settings: settings, logger: Logger(label: "cli-runner"))
        defer { Task { try? await workers.shutdown() } }

        // 1. Health check + load operations list concurrently
        printProgress("Checking availability…")
        await withTaskGroup(of: Void.self) { group in
            for type in jobTypes {
                let label = appLabel(type)
                group.addTask {
                    guard let svc = await workers.services[type] else { return }
                    do {
                        _ = try await svc.checkAvailability()
                        if await svc.available {
                            try await svc.loadAvailableOperations()
                            printProgress("  [\(label)] reachable ✓")
                        } else {
                            printProgress("  [\(label)] unreachable")
                        }
                    } catch {
                        printProgress("  [\(label)] error: \(error)")
                    }
                }
            }
        }

        // 2. Run benchmarks per app
        var appResults: [String: AppResult] = [:]

        for type in jobTypes {
            guard let svc = await workers.services[type] else { continue }
            let label = appLabel(type)

            guard await svc.available else {
                printProgress("  [\(label)] skipped (unavailable)")
                continue
            }

            let availableOps = await svc.availableOperations

            let opsToRun: [String]
            if operations.contains("all") {
                opsToRun = availableOps.keys.sorted()
            } else {
                opsToRun = operations
            }

            printProgress("")
            printProgress("[\(label)] running \(opsToRun.count) operation(s)…")

            var benchmarks: [String: [String: BenchmarkResult]] = [:]
            var runtimeMode: String? = nil

            for op in opsToRun {
                printProgress("  → \(op)")
                do {
                    let result = try await svc.runBenchmark(operation: op, scenario: scenario).get()
                    runtimeMode = result.meta.runtimeMode ?? result.meta.runtime
                    for (opKey, anyCodable) in result.benchmarks {
                        let flat = anyCodable.flatResults(operationName: opKey)
                        for entry in flat {
                            benchmarks[opKey, default: [:]][entry.scenario] = entry.result
                        }
                    }
                } catch {
                    printError("[\(label)] \(op) failed: \(error)")
                }
            }

            appResults[label] = AppResult(
                endpoint: settings.getForType(type: type),
                runtime: runtimeMode,
                benchmarks: benchmarks
            )
        }

        return RunResults(
            apps: appResults,
            ranAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}
