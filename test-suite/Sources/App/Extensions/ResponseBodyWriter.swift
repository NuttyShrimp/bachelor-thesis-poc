import Elementary
import Hummingbird

extension ResponseBodyWriter {
    mutating func writeSSE(event: String? = nil, html: some HTML) async throws {
        if let event {
            try await write(ByteBuffer(string: "event: \(event)\n"))
        }
        try await write(ByteBuffer(string: "data: "))
        try await writeHTML(html)
        try await write(ByteBuffer(string: "\n\n"))
    }
}
