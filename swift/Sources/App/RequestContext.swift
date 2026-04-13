import Foundation
import Hummingbird
import IkigaJSON
import Prometheus

struct JSONSnakeCaseEncoder: ResponseEncoder {
    let encoder: IkigaJSONEncoder

    init() {
        var encoder = IkigaJSONEncoder()
        encoder.settings.keyEncodingStrategy = .convertToSnakeCase
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
    var requestEncoder: JSONSnakeCaseEncoder { .init() }
    var coreContext: CoreRequestContextStorage

    init(source: Source) {
        self.coreContext = .init(source: source)
    }
}
