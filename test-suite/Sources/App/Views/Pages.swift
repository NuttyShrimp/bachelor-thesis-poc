import Elementary
import ElementaryHTMXSSE
import TestSuiteLibrary

struct IndexPage: HTML {
    let endpoints: JobSettings
    let availabilities: WorkerInfo<Bool>

    var body: some HTML {
        h1(.class("text-xl font-semibold")) { "PHP vs Swift test suite" }
        div(.class("flex flex-col gap-4")) {
            div(.class("flex gap-4")) {
                form(.action("/job/settings"), .method(.post)) {
                    fieldset(
                        .class("fieldset bg-base-200 border-base-300 rounded-box w-xs border p-4")
                    ) {
                        legend(.class("fieldset-legend")) { "API Endpoints" }
                        label(.for("swiftEndpoint"), .class("label")) {
                            "Swift Endpoint"
                        }
                        input(
                            .required, .name("swiftEndpoint"),
                            .placeholder("http://localhost:8081"),
                            .value(endpoints.swiftEndpoint),
                            .class("input"))

                        label(.for("phpEndpoint"), .class("label")) {
                            "PHP Endpoint"
                        }
                        input(
                            .required, .name("phpEndpoint"),
                            .placeholder("http://localhost:5000"),
                            .value(endpoints.phpEndpoint),
                            .class("input"))

                        label(.for("octaneEndpoint"), .class("label")) { "PHP Octane Endpoint" }
                        input(
                            .required, .name("octaneEndpoint"),
                            .placeholder("http://localhost:6000"),
                            .value(endpoints.octaneEndpoint),
                            .class("input"))

                        button(.type(.submit), .class("btn btn-info")) { "Update" }
                    }
                }

                div(
                    .class(
                        "bg-base-200 border-base-300 rounded-box w-xs border p-4 space-y-4"
                    )
                ) {
                    button(.class("btn btn-info")) { "Run Swift benchmarks" }
                    button(.class("btn btn-info")) { "Run PHP-fpm benchmarks" }
                    button(.class("btn btn-info")) { "Run PHP-octane benchmarks" }
                    button(.class("btn btn-info")) { "Run All benchmarks" }
                }

                div(.hx.ext(.sse), .sse.connect("/availability"), .hx.swap(.innerHTML)) {
                    WorkerHealth(availabilities: availabilities)
                }
            }

            div(.class("collapse collapse-arrow bg-base-100 border-base-300 border")) {
                input(.type(.checkbox))
                div(.class("collapse-title font-semibold")) { "Swift" }
                div(.class("collapse-content"), .id("swift-results")) {
                    p {
                        "swift results will be shown here"
                    }
                }
            }

            div(.class("collapse collapse-arrow bg-base-100 border-base-300 border")) {
                input(.type(.checkbox))
                div(.class("collapse-title font-semibold")) { "PHP-fpm" }
                div(.class("collapse-content"), .id("php-results")) {
                    p {
                        "PHP-fpm results will be shown here"
                    }
                }
            }

            div(.class("collapse collapse-arrow bg-base-100 border-base-300 border")) {
                input(.type(.checkbox))
                div(.class("collapse-title font-semibold")) { "PHP Octane" }
                div(.class("collapse-content"), .id("octane-results")) {
                    p {
                        "PHP Octane results will be shown here"
                    }
                }
            }
        }
    }
}
