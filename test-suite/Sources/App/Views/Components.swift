import Elementary
import ElementaryHTMX
import ElementaryHTMXSSE
import TestSuiteLibrary

struct SuccessLabel: HTML {
    var body: some HTML {
        div(
            .class("status status-success"),
            .custom(name: "aria-label", value: "success")
        ) { "" }
    }
}

struct ErrorLabel: HTML {
    var body: some HTML {
        div(
            .class("status status-error"),
            .custom(name: "aria-label", value: "error")
        ) { "" }
    }
}

struct WorkerHealth: HTML {
    let availabilities: WorkerInfo<Bool>

    var body: some HTML {
        ul(.class("list bg-base-200 border border-base-300 rounded-box shadow-sm p-4 w-xs")) {
            li(.class("list-row")) {
                div(.class("list-col-grow")) {
                    p {
                        "Swift"
                    }
                }
                div {
                    if availabilities.swift {
                        SuccessLabel()
                    } else {
                        ErrorLabel()
                    }
                }
            }
            li(.class("list-row")) {
                div(.class("list-col-grow")) {
                    p {
                        "PHP-FPM"
                    }
                }
                div {
                    if availabilities.php {
                        SuccessLabel()
                    } else {
                        ErrorLabel()
                    }
                }
            }
            li(.class("list-row")) {
                div(.class("list-col-grow")) {
                    p {
                        "Octane"
                    }
                }
                div {
                    if availabilities.octane {
                        SuccessLabel()
                    } else {
                        ErrorLabel()
                    }
                }
            }

        }
    }
}

struct WorkerOperations: HTML {
    let operations: WorkerInfo<[String: [String]?]>

    var body: some HTML {
        div {
            p {
                "abc"
            }
        }
    }
}
