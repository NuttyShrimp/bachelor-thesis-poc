import Foundation
import Hummingbird
import Prometheus

struct JSONSnakeCaseEncoder: ResponseEncoder {
    let encoder: JSONEncoder

    init() {
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func encode(_ value: some Encodable, from request: Request, context: some RequestContext) throws
        -> Response
    {
        return try encoder.encode(value, from: request, context: context)
    }
}

struct MyRequestContext: RequestContext {
    var requestEncoder: JSONSnakeCaseEncoder { .init() }
    var coreContext: CoreRequestContextStorage

    init(source: Source) {
        self.coreContext = .init(source: source)
    }
}
