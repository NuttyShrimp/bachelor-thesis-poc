import ArgumentParser
import Hummingbird
import Logging

@main
struct AppCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Test suite for this bachelorstudy",
        subcommands: [WebCommand.self, CliCommand.self],
        defaultSubcommand: WebCommand.self
    )
}

struct WebCommand: AsyncParsableCommand, AppArguments {
    static let configuration = CommandConfiguration(
        commandName: "web"
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

struct CliCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cli"
    )

    func run() async throws {
        print("running test suite in CLI mode")
    }
}

/// Extend `Logger.Level` so it can be used as an argument
extension Logger.Level: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        guard let value = Self(rawValue: argument) else { return nil }
        self = value
    }
}
