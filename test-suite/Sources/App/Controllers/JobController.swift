import Hummingbird
import Jobs
import TestSuiteLibrary

struct JobController {
    let service: JobService

    func addRoutes(to group: RouterGroup<some RequestContext>) {
        group
            .post("/settings", use: self.update)
    }

    @Sendable
    private func update(_ request: Request, context: some RequestContext) async throws
        -> Response
    {
        let settings = try await request.decode(as: JobSettings.self, context: context)
        await service.modifySettings(settings)
        await service.checkAvailability()
        return Response.redirect(to: "/")
    }
}
