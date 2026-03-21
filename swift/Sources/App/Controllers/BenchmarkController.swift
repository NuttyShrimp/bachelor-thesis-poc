import Hummingbird

struct BenchmarkController: Sendable {
    func addRoutes(to group: RouterGroup<some RequestContext>) {
        let group =
            group
            .group("/benchmarks")

        group
            .get(use: self.list)
    }

    func list(_ request: Request, ctx: some RequestContext) async throws -> [BenchmarkOptions] {

    }
}
