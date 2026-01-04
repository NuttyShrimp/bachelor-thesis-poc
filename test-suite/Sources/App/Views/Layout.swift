import Elementary

extension MainLayout: Sendable where Body: Sendable {}

struct MainLayout<Body: HTML>: HTMLDocument {
    var title: String { "PHP vs Swift benchmark UI" }
    @HTMLBuilder var pageContent: Body

    var head: some HTML {
        meta(.charset(.utf8))
        meta(.custom(name: "viewport", value: "width=device-width, initial-scale=1.0"))
        script(.src("/htmx.min.js")) {}
        script(.src("/htmxsse.min.js")) {}
        link(.href("/main.css"), .rel(.stylesheet))
    }

    var body: some HTML {
        main {
            pageContent
        }
    }
}
