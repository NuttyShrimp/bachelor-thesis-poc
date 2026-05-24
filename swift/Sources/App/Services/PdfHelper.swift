import Foundation

struct PdfHelper {
    let content: String

    private static let cachedExecutableURL: URL? = try? resolveWkhtmltopdfExecutable()

    func render() throws -> Data {
        let process = Process()
        guard let executableURL = PdfHelper.cachedExecutableURL else {
            throw PdfHelperError.executableNotFound
        }
        process.executableURL = executableURL
        process.arguments = ["-q", "-", "-"]

        let inputPipe = Pipe()
        let outputPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = FileHandle.standardError

        do {
            try process.run()
        } catch {
            throw PdfHelperError.failedToStart(underlying: error)
        }

        let htmlData = Data(content.utf8)

        inputPipe.fileHandleForWriting.write(htmlData)
        try? inputPipe.fileHandleForWriting.close()

        let rawOutput = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PdfHelperError.renderFailed(status: process.terminationStatus)
        }

        guard !rawOutput.isEmpty else {
            throw PdfHelperError.emptyOutput
        }

        return try extractPdfData(from: rawOutput)
    }

    private func extractPdfData(from rawOutput: Data) throws -> Data {
        let pdfMagic = Data("%PDF-".utf8)
        guard let range = rawOutput.range(of: pdfMagic) else {
            throw PdfHelperError.invalidPdfOutput
        }

        return Data(rawOutput[range.lowerBound...])
    }

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
