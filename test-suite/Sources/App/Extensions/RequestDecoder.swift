import Foundation
import Hummingbird

struct GeneralRequestDecoder: RequestDecoder {
    let url_decoder = URLEncodedFormDecoder()
    let json_decoder = JSONDecoder()

    func decode<T>(_ type: T.Type, from request: Request, context: some RequestContext) async throws
        -> T where T: Decodable
    {
        if request.headers[.contentType] == "application/x-www-form-urlencoded" {
            return try await self.url_decoder.decode(type, from: request, context: context)
        }
        if request.headers[.contentType] == "application/json" {
            return try await self.json_decoder.decode(type, from: request, context: context)
        }
        throw HTTPError(.unsupportedMediaType)
    }
}
