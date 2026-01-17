import Hummingbird
import HummingbirdElementary
import TestSuiteLibrary

struct UIController<Context: RequestContext> {
    let service: JobService

    func addRoutes(to group: RouterGroup<Context>) {
        group
            .get(use: self.index)
    }

    @Sendable
    private func index(_ request: Request, context: Context) async throws -> HTMLResponse {
        let settings = await service.settings
        return HTMLResponse {
            MainLayout {
                IndexPage(
                    swiftUrl: settings.swiftEndpoint, phpUrl: settings.phpEndpoint,
                    octaneUrl: settings.octaneEndpoint)
            }
        }
    }
}
