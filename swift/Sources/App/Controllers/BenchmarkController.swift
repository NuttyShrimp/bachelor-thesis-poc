import Hummingbird
import HTTPTypes
import Logging
import Foundation

struct BenchmarkController: Sendable {
    var benchmark: BenchmarkService
    var logger: Logger

    func addRoutes(to group: RouterGroup<MyRequestContext>) {
        group
            .group("/benchmarks")
            .get(use: self.list)
            .get("run/:operation", use: self.run)
            .get("single/:operation/:scenario", use: self.single)
            .post("preload", use: self.preloadData)
    }

    func list(_ request: Request, ctx: MyRequestContext) async throws
        -> BenchmarkOptionsResponse
    {
        return BenchmarkOptionsResponse(
            operations: benchmark.getAvailableOperations(), meta: CreateMeta())
    }

    func run(_ request: Request, ctx: MyRequestContext) async throws -> BenchmarkRunResponse {
        let operation = ctx.parameters.get("operation")!
        do {
            let results = try await benchmark.runOperation(for: operation)
            return BenchmarkRunResponse(benchmarks: [operation: results], meta: CreateMeta())
        } catch {
            logger.error("Failed to run benchmark operation: \(error)")
            throw HTTPError(.internalServerError)
        }
    }

    func single(_ request: Request, ctx: MyRequestContext) async throws -> Response {
        let operation = ctx.parameters.get("operation")!
        let scenario = ctx.parameters.get("scenario")!
        do {
            let result = try await benchmark.runScenario(for: operation, scenario)
            switch result {
            case .json(let value):
                return try ctx.responseEncoder.encode(value, from: request, context: ctx)
            case .file(let data, let filename, let contentType):
                return downloadResponse(data: data, filename: filename, contentType: contentType)
            }
        } catch {
            logger.error("Failed to run benchmark operation: \(error)")
            throw HTTPError(.internalServerError)
        }
    }

    private func downloadResponse(data: Data, filename: String, contentType: String) -> Response {
        var response = Response(
            status: .ok,
            headers: [:],
            body: .init(byteBuffer: ByteBuffer(bytes: data))
        )
        response.headers[.contentType] = contentType
        response.headers[HTTPField.Name("Content-Disposition")!] = "attachment; filename=\"\(filename)\""
        return response
    }

    func preloadData(_ request: Request, ctx: MyRequestContext) -> Response {
        benchmark.preloadData()
        return .init(status: .noContent)
    }
}
