import ArgumentParser
import Hummingbird
import Logging
import TestSuiteCli
import TestSuiteLibrary

@main
struct AppCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Test suite for the bachelor's study — benchmark PHP-FPM, PHP Octane & Swift",
        subcommands: [WebCommand.self, CliCommand.self],
        defaultSubcommand: WebCommand.self
    )
}

struct WebCommand: AsyncParsableCommand, AppArguments {
    static let configuration = CommandConfiguration(
        commandName: "web",
        abstract: "Start the web dashboard (default)"
    )

    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    @Option(name: .shortAndLong)
    var logLevel: Logger.Level?

    func run() async throws {
        let app = try await buildApplication(self)
        try await app.runService()
    }
}

// MARK: - CLI Command

struct CliCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cli",
        abstract: "Run benchmarks from the command line and compare results across all apps"
    )

    // ── Endpoint options ──────────────────────────────────────────────────────

    @Option(
        name: [.customLong("swift-endpoint"), .customShort("s")],
        help: "Swift app endpoint (default: http://localhost:3000)"
    )
    var swiftEndpoint: String = "http://localhost:3000"

    @Option(
        name: [.customLong("php-endpoint"), .customShort("p")],
        help: "PHP-FPM app endpoint (default: http://localhost:8000)"
    )
    var phpEndpoint: String = "http://localhost:8000"

    @Option(
        name: [.customLong("octane-endpoint"), .customShort("o")],
        help: "PHP Octane app endpoint (default: http://localhost:8001)"
    )
    var octaneEndpoint: String = "http://localhost:8001"

    // ── Worker selection ──────────────────────────────────────────────────────

    @Option(
        name: .customLong("workers"),
        help: "Comma-separated list of workers to include: swift, php, octane (default: all)"
    )
    var workersRaw: String = "swift,php,octane"

    // ── Operation selection ───────────────────────────────────────────────────

    @Option(
        name: [.customLong("operation"), .customShort("b")],
        help: "Benchmark operation to run, or 'all' to run everything (default: all)"
    )
    var operation: String = "all"

    @Option(
        name: .customLong("scenario"),
        help: "Optional scenario name to pass to the benchmark (e.g. large_cart)"
    )
    var scenario: String?

    // ── Output format ─────────────────────────────────────────────────────────

    @Option(
        name: [.customLong("format"), .customShort("f")],
        help: "Output format: table (default) or json"
    )
    var formatRaw: String = "table"

    // ── Output destination ────────────────────────────────────────────────────

    @Option(
        name: .customLong("output"),
        help: "Write output to a file instead of stdout (optional)"
    )
    var outputFile: String?

    // ── Execution ─────────────────────────────────────────────────────────────

    func run() async throws {
        let format = OutputFormat(rawValue: formatRaw.lowercased()) ?? .table
        let jobTypes = parseWorkers(workersRaw)

        if jobTypes.isEmpty {
            printError("No valid workers specified. Choose from: swift, php, octane")
            throw ExitCode.failure
        }

        let settings = JobSettings(
            swiftEndpoint: swiftEndpoint,
            phpEndpoint: phpEndpoint,
            octaneEndpoint: octaneEndpoint
        )

        let ops: [String] = operation == "all" ? ["all"] : [operation]

        printProgress("Starting benchmark run…")
        printProgress("  Workers : \(jobTypes.map { label(for: $0) }.joined(separator: ", "))")
        printProgress("  Operation: \(operation)")
        if let sc = scenario { printProgress("  Scenario : \(sc)") }
        printProgress("  Format  : \(format.rawValue)")
        printProgress("")

        let runner = CliRunner(settings: settings)
        let results = await runner.run(jobTypes: jobTypes, operations: ops, scenario: scenario)

        let output: String
        switch format {
        case .json:
            output = BenchmarkFormatter.formatJSON(results)
        case .table:
            output = BenchmarkFormatter.formatTable(results)
        }

        if let path = outputFile {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
            printProgress("\nResults written to \(path)")
        } else {
            print(output)
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func parseWorkers(_ raw: String) -> [JobType] {
        raw.split(separator: ",")
            .compactMap { token -> JobType? in
                switch token.trimmingCharacters(in: .whitespaces).lowercased() {
                case "swift":  return .Swift
                case "php":    return .PHP
                case "octane": return .PHPOctane
                default:
                    printError("Unknown worker '\(token)' — valid values: swift, php, octane")
                    return nil
                }
            }
    }

    private func label(for type: JobType) -> String {
        switch type {
        case .Swift:     return "swift"
        case .PHP:       return "php-fpm"
        case .PHPOctane: return "php-octane"
        }
    }
}

/// Extend `Logger.Level` so it can be used as an argument
extension Logger.Level: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        guard let value = Self(rawValue: argument) else { return nil }
        self = value
    }
}

