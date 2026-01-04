import Hummingbird
import HummingbirdElementary

struct UIController<Context: RequestContext> {
    func addRoutes(to group: RouterGroup<Context>) {
        group
            .get(use: self.index)
    }

    @Sendable
    private func index(_ request: Request, context: Context) async throws -> HTMLResponse {
        return HTMLResponse {
            MainLayout {
                IndexPage()
            }
        }
    }
}
