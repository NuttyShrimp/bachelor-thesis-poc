import Hummingbird

struct BenchmarkController: Sendable {
    var benchmark: BenchmarkService

    func addRoutes(to group: RouterGroup<some RequestContext>) {
        group
            .group("/benchmarks")
            .get(use: self.list)
            .get("run/:operation", use: self.run)
    }

    func list(_ request: Request, ctx: some RequestContext) async throws
        -> BenchmarkOptionsResponse
    {
        return BenchmarkOptionsResponse(
            operations: benchmark.getAvailableOperations(), meta: CreateMeta())
    }

    func run(_ request: Request, ctx: some RequestContext) async throws -> BenchmarkRunResponse {
        let operation = ctx.parameters.get("operation")!
        var results = try await benchmark.runOperation(for: operation)
        return BenchmarkRunResponse(benchmarks: [operation: results], meta: CreateMeta())
    }
}
