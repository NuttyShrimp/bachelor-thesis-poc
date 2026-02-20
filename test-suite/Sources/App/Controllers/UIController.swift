import Hummingbird
import HummingbirdElementary
import Observation
import TestSuiteLibrary

struct UIController<Context: RequestContext> {
    let service: JobService

    func addRoutes(to group: RouterGroup<Context>) {
        group
            .get(use: self.index)
            .get("availability", use: self.getAvailability)
            .get("jobs", use: self.getJobs)
    }

    @Sendable
    private func index(_ request: Request, context: Context) async throws -> HTMLResponse {
        let page =
            IndexPage(
                endpoints: await service.settings,
                availabilities: await service.availability
            )
        return HTMLResponse {
            MainLayout {
                page
            }
        }
    }

    @Sendable
    private func getAvailability(_ request: Request, context: Context) async throws -> Response {
        Response(
            status: .ok,
            headers: [.contentType: "text/event-stream"],
            body: .init { writer in
                for await availabilites in await service.getAvailabilityObservation() {
                    try await writer.writeSSE(html: WorkerHealth(availabilities: availabilites))
                }
                try await writer.finish(nil)
            }
        )
    }

    @Sendable
    private func getJobs(_ request: Request, context: Context) async throws -> Response {
        Response(
            status: .ok,
            headers: [.contentType: "text/event-stream"],
            body: .init { writer in
                for await operations in await service.getOperationsObservation() {
                    try await writer.writeSSE(html: WorkerOperations(operations: operations))
                }
                try await writer.finish(nil)
            }
        )
    }
}
