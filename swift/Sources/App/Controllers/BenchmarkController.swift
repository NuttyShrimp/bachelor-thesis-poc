import Hummingbird
import Logging

struct BenchmarkController: Sendable {
    var benchmark: BenchmarkService
    var logger: Logger

    func addRoutes(to group: RouterGroup<MyRequestContext>) {
        group
            .group("/benchmarks")
            .get(use: self.list)
            .get("run/:operation", use: self.run)
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
}
