import Foundation
import Hummingbird

#if ReerJSON
    import ReerJSON
#endif

struct JSONSnakeCaseEncoder: ResponseEncoder, Sendable {
    #if ReerJSON
        let encoder: ReerJSONEncoder
    #else
        let encoder: JSONEncoder
    #endif

    init() {
        let encoder = createEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    func encode(_ value: some Encodable, from request: Request, context: some RequestContext) throws
        -> Response
    {
        let data = try encoder.encode(value)
        let buffer = ByteBuffer(bytes: data)
        var response = Response(
            status: .ok,
            headers: [:],
            body: .init(byteBuffer: buffer)
        )
        response.headers[.contentType] = "application/json; charset=utf-8"
        return response
    }
}

#if ReerJSON
    extension ReerJSONDecoder: @unchecked Sendable {}
    extension ReerJSONEncoder: @unchecked Sendable {}

    extension ReerJSONDecoder: RequestDecoder {
        public func decode<T>(
            _ type: T.Type, from request: Request, context: some RequestContext
        ) async throws -> T where T: Decodable {
            let buffer = try await request.body.collect(upTo: context.maxUploadSize)
            let data = Data(buffer: buffer)
            return try self.decode(T.self, from: data)
        }
    }
#endif

struct JSONSnakeCaseDecoder: RequestDecoder, Sendable {
    #if ReerJSON
        let decoder: ReerJSONDecoder
    #else
        let decoder: JSONDecoder
    #endif

    init() {
        let decoder = createDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func decode<T>(_ type: T.Type, from request: Request, context: some RequestContext) async throws
        -> T where T: Decodable
    {
        guard let header = request.headers[.contentType] else { throw HTTPError(.badRequest) }
        guard let mediaType = MediaType(from: header) else { throw HTTPError(.badRequest) }
        switch mediaType {
        case .applicationJson:
            return try await decoder.decode(type, from: request, context: context)
        case .applicationUrlEncoded:
            return try await URLEncodedFormDecoder().decode(type, from: request, context: context)
        default:
            throw HTTPError(.badRequest)
        }
    }
}

struct MyRequestContext: RequestContext {
    #if ReerJSON
        var requestDecoder: JSONSnakeCaseDecoder { JSONSnakeCaseDecoder() }
        var responseEncoder: JSONSnakeCaseEncoder { JSONSnakeCaseEncoder() }
    #else
        static let sharedRequestDecoder = JSONSnakeCaseDecoder()
        static let sharedResponseEncoder = JSONSnakeCaseEncoder()

        var requestDecoder: JSONSnakeCaseDecoder { Self.sharedRequestDecoder }
        var responseEncoder: JSONSnakeCaseEncoder { Self.sharedResponseEncoder }
    #endif
    var coreContext: CoreRequestContextStorage

    init(source: Source) {
        self.coreContext = .init(source: source)
    }
}
