import Foundation
import Subprocess

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

struct PdfHelper {
    let content: String

    private static let cachedExecutableURL: URL? = try? resolveWkhtmltopdfExecutable()

    func render() async throws -> Data {
        guard let executableURL = PdfHelper.cachedExecutableURL else {
            throw PdfHelperError.executableNotFound
        }

        do {
            // Run process asynchronously using Subprocess.run
            let result = try await Subprocess.run(
                .path(FilePath(executableURL.path)),
                arguments: ["-q", "-", "-"],
                input: .string(content),
                output: .data(limit: 10 * 1024 * 1024)
            )

            // Verify termination status
            guard result.terminationStatus.isSuccess else {
                let code: Int32
                switch result.terminationStatus {
                case .exited(let status):
                    code = Int32(status)
                case .signaled(let signal):
                    code = Int32(signal)
                }
                throw PdfHelperError.renderFailed(status: code)
            }

            let rawOutput = result.standardOutput
            guard !rawOutput.isEmpty else {
                throw PdfHelperError.emptyOutput
            }

            return Data(rawOutput)
            // return try extractPdfData(from: rawOutput)
        } catch {
            throw PdfHelperError.failedToStart(underlying: error)
        }
    }

    // private func extractPdfData(from rawOutput: Data) throws -> Data {
    //     let pdfMagic = Data("%PDF-".utf8)
    //     guard let range = rawOutput.range(of: pdfMagic) else {
    //         throw PdfHelperError.invalidPdfOutput
    //     }
    //     return Data(rawOutput[range.lowerBound...])
    // }

    private static func resolveWkhtmltopdfExecutable() throws -> URL {
        if let executable = locateExecutableInPath(named: "wkhtmltopdf") {
            return executable
        }
        let fallback = URL(fileURLWithPath: "/usr/bin/wkhtmltopdf")
        if FileManager.default.isExecutableFile(atPath: fallback.path) {
            return fallback
        }
        throw PdfHelperError.executableNotFound
    }

    private static func locateExecutableInPath(named executableName: String) -> URL? {
        let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for directory in path.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(directory))
                .appendingPathComponent(executableName)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}

enum PdfHelperError: Error {
    case executableNotFound
    case failedToStart(underlying: Error)
    case renderFailed(status: Int32)
    case emptyOutput
    case invalidPdfOutput
}
