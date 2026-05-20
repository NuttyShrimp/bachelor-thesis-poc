import Foundation

struct AnyEncodable: Encodable, @unchecked Sendable {
    private let encodeImpl: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encodeImpl = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeImpl(encoder)
    }
}

enum BenchmarkSingleResult: Sendable {
    case json(AnyEncodable)
    case file(data: Data, filename: String, contentType: String)
}
