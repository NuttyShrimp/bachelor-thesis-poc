import Foundation
import TestSuiteLibrary

// MARK: - Output format

public enum OutputFormat: String, CaseIterable, Sendable {
    case table
    case json
}

// MARK: - Collected results

/// All results collected from one run, keyed by app label
public struct RunResults: Encodable, Sendable {
    public let apps: [String: AppResult]
    public let ranAt: String

    enum CodingKeys: String, CodingKey {
        case apps
        case ranAt = "ran_at"
    }
}

/// Results for one app (endpoint + optional runtime label + operation→scenario→result)
public struct AppResult: Encodable, Sendable {
    public let endpoint: String
    public let runtime: String?
    public let benchmarks: [String: [String: BenchmarkResult]]
}

// MARK: - Formatter

public enum BenchmarkFormatter {

    // ─── JSON output ──────────────────────────────────────────────────────────

    public static func formatJSON(_ results: RunResults) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(results) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    // ─── Table output ─────────────────────────────────────────────────────────

    /// Render all results as human-readable ASCII tables.
    public static func formatTable(_ results: RunResults) -> String {
        var out = ""

        // Collect all (operation, scenario) pairs
        var pairs: [(operation: String, scenario: String)] = []
        for (_, appResult) in results.apps.sorted(by: { $0.key < $1.key }) {
            for (op, scenarios) in appResult.benchmarks.sorted(by: { $0.key < $1.key }) {
                for scenario in scenarios.keys.sorted() {
                    let pair = (operation: op, scenario: scenario)
                    if !pairs.contains(where: { pairEqual($0, pair) }) {
                        pairs.append(pair)
                    }
                }
            }
        }

        let appLabels = results.apps.keys.sorted()

        out += headerBox("Benchmark Results — \(results.ranAt)")
        out += "\n\n"

        for pair in pairs {
            out += sectionHeader("\(pair.operation)  ›  \(pair.scenario)")
            out += "\n"
            let rows: [(app: String, result: BenchmarkResult?)] = appLabels.map { label in
                (app: label, result: results.apps[label]?.benchmarks[pair.operation]?[pair.scenario])
            }
            out += benchmarkTable(rows: rows)
            out += "\n\n"
        }

        out += sectionHeader("Ranking by avg_time_ms (lower is better)")
        out += "\n"
        out += rankingTable(pairs: pairs, apps: results.apps, appLabels: appLabels)
        out += "\n"

        return out
    }

    // MARK: - Private table helpers

    private static func headerBox(_ text: String) -> String {
        let line = String(repeating: "═", count: text.count + 4)
        return "╔\(line)╗\n║  \(text)  ║\n╚\(line)╝"
    }

    private static func sectionHeader(_ text: String) -> String {
        let width = max(60, text.count + 4)
        let line = String(repeating: "─", count: width)
        return "\(line)\n  \(text)\n\(line)"
    }

    private static func benchmarkTable(rows: [(app: String, result: BenchmarkResult?)]) -> String {
        // Column: (header, width, value extractor)
        let cols: [(String, Int, (BenchmarkResult) -> String)] = [
            ("App",       18, { _ in "" }),
            ("avg ms",    10, { r in fmt(r.avgTimeMs) }),
            ("min ms",    10, { r in fmt(r.minTimeMs) }),
            ("max ms",    10, { r in fmt(r.maxTimeMs) }),
            ("p50 ms",    10, { r in fmt(r.p50TimeMs) }),
            ("p95 ms",    10, { r in fmt(r.p95TimeMs) }),
            ("p99 ms",    10, { r in fmt(r.p99TimeMs) }),
            ("stddev",    10, { r in fmt(r.stdDevMs) }),
            ("mem MB",    10, { r in fmt(r.memoryUsedMb) }),
            ("iters",      7, { r in r.iterations.map(String.init) ?? "—" }),
        ]

        func cell(_ s: String, _ w: Int) -> String {
            " \(s.padding(toLength: w, withPad: " ", startingAt: 0)) │"
        }
        func divider(_ l: String, _ m: String, _ r: String) -> String {
            var s = l
            for (i, c) in cols.enumerated() {
                s += String(repeating: "─", count: c.1 + 2)
                s += i < cols.count - 1 ? m : r
            }
            return s
        }
        func dataRow(_ cells: [String]) -> String {
            "│" + cells.enumerated().map { cell($1, cols[$0].1) }.joined()
        }

        var out = divider("┌", "┬", "┐") + "\n"
        out += dataRow(cols.map { $0.0 }) + "\n"
        out += divider("├", "┼", "┤") + "\n"

        for (appLabel, result) in rows {
            let cells = cols.enumerated().map { i, col -> String in
                guard i != 0, let r = result else { return i == 0 ? appLabel : "—" }
                return i == 0 ? appLabel : col.2(r)
            }
            // cols[0] is the app name column — patch it in
            var patched = cells
            patched[0] = appLabel
            out += dataRow(patched) + "\n"
        }

        out += divider("└", "┴", "┘")
        return out
    }

    private static func rankingTable(
        pairs: [(operation: String, scenario: String)],
        apps: [String: AppResult],
        appLabels: [String]
    ) -> String {
        struct RankRow {
            let operation: String
            let scenario: String
            let rank: Int
            let app: String
            let avgMs: Double
            let speedupVsWorst: String
        }

        var rankRows: [RankRow] = []
        for pair in pairs {
            var appAvgs: [(app: String, avg: Double)] = []
            for label in appLabels {
                if let avg = apps[label]?.benchmarks[pair.operation]?[pair.scenario]?.avgTimeMs {
                    appAvgs.append((app: label, avg: avg))
                }
            }
            let sorted = appAvgs.sorted { $0.avg < $1.avg }
            let worst = sorted.last?.avg ?? 1
            for (rank, entry) in sorted.enumerated() {
                let speedup = worst / max(entry.avg, 0.001)
                let speedupStr = speedup >= 1.01 ? String(format: "%.2fx faster", speedup) : "—"
                rankRows.append(RankRow(
                    operation: pair.operation, scenario: pair.scenario,
                    rank: rank + 1, app: entry.app, avgMs: entry.avg,
                    speedupVsWorst: speedupStr
                ))
            }
        }

        let w = (op: 28, sc: 22, rk: 5, app: 18, avg: 12, sp: 20)
        func hr(_ l: String, _ m: String, _ r: String) -> String {
            "\(l)\(rep(w.op))\(m)\(rep(w.sc))\(m)\(rep(w.rk))\(m)\(rep(w.app))\(m)\(rep(w.avg))\(m)\(rep(w.sp))\(r)"
        }
        func rep(_ n: Int) -> String { String(repeating: "─", count: n + 2) }
        func c(_ s: String, _ n: Int) -> String { " \(s.padding(toLength: n, withPad: " ", startingAt: 0)) │" }
        func dataRow(_ r: RankRow) -> String {
            "│" + c(r.operation, w.op) + c(r.scenario, w.sc) + c(String(r.rank), w.rk)
            + c(r.app, w.app) + c(fmt(r.avgMs), w.avg) + c(r.speedupVsWorst, w.sp)
        }

        var out = hr("┌", "┬", "┐") + "\n"
        out += "│" + c("Operation", w.op) + c("Scenario", w.sc) + c("#", w.rk)
             + c("App", w.app) + c("avg ms", w.avg) + c("Speedup vs slowest", w.sp) + "\n"
        out += hr("├", "┼", "┤") + "\n"
        for r in rankRows { out += dataRow(r) + "\n" }
        out += hr("└", "┴", "┘")
        return out
    }

    private static func fmt(_ v: Double) -> String { String(format: "%.3f", v) }
}

private func pairEqual(
    _ a: (operation: String, scenario: String),
    _ b: (operation: String, scenario: String)
) -> Bool {
    a.operation == b.operation && a.scenario == b.scenario
}
