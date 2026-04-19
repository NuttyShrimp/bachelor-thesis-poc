import Foundation

struct PdfHelper {
    let content: String

    func render() throws -> Data {
        let process = Process()
        process.executableURL = try resolvePaperMuncherExecutable()
        process.arguments = ["--quiet", "--output", "-", "pipe:stdin"]

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
        var stdinPayload = Data()
        stdinPayload.append(Data("HTTP/1.1 200 OK\r\n".utf8))
        stdinPayload.append(Data("Content-Type: text/html; charset=utf-8\r\n".utf8))
        stdinPayload.append(Data("Content-Length: \(htmlData.count)\r\n\r\n".utf8))
        stdinPayload.append(htmlData)

        inputPipe.fileHandleForWriting.write(stdinPayload)
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

    private func resolvePaperMuncherExecutable() throws -> URL {
        if let executable = locateExecutableInPath(named: "paper-muncher") {
            return executable
        }

        let fallback = URL(fileURLWithPath: "/usr/local/bin/paper-muncher")
        if FileManager.default.isExecutableFile(atPath: fallback.path) {
            return fallback
        }

        throw PdfHelperError.executableNotFound
    }

    private func locateExecutableInPath(named executableName: String) -> URL? {
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
