import Foundation
import Hummingbird

#if ReerJSON
    import ReerJSON
#endif

struct JSONSnakeCaseEncoder: ResponseEncoder {
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

struct MyRequestContext: RequestContext {
    var requestDecoder: RequestDecoder {
        let decoder = createDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    var responseEncoder: JSONSnakeCaseEncoder { .init() }
    var coreContext: CoreRequestContextStorage

    init(source: Source) {
        self.coreContext = .init(source: source)
    }
}
