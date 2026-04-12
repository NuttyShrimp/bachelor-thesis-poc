//
//  Utils.swift
//  bap-swift
//
//  Created by Jan Lecoutere on 22/03/2026.
//

import Foundation
import Metrics
import Prometheus
import SystemPackage

enum SystemConfiguration {
    static let pageByteCount = sysconf(Int32(_SC_PAGESIZE))
}

func reportMemory() -> Double {
    let factory = MetricsSystem.factory as? PrometheusMetricsFactory
    if factory != nil {
        let promData = factory?.registry.emitToString().split(separator: "\n")
        guard promData != nil && promData!.count >= 13 else {
            return 0.0
        }
        // # TYPE process_cpu_seconds_total gauge
        // process_cpu_seconds_total 3.5260290000000003
        // # TYPE process_virtual_memory_bytes gauge
        // process_virtual_memory_bytes 2601545728.0
        // # TYPE process_max_fds gauge
        // process_max_fds 524288.0
        // # TYPE http_server_active_requests gauge
        // http_server_active_requests{http_request_method="GET"} 1.0
        // # TYPE process_open_fds gauge
        // process_open_fds 63.0
        // # TYPE process_resident_memory_bytes gauge
        // process_resident_memory_bytes 403148800.0
        // # TYPE process_start_time_seconds gauge
        // process_start_time_seconds 1774638005.0

        guard
            let memUsageRow = promData?.first(where: {
                $0.contains(/^process_resident_memory_bytes \d+/)
            })
        else {
            return 0
        }

        let memUsageStr = memUsageRow.replacingOccurrences(
            of: "process_resident_memory_bytes ", with: ""
        ).trimmingCharacters(in: [" "])
        guard
            let memUsage = Double(memUsageStr)
        else {
            return 0
        }
        let usedInMb = memUsage / 1048576.0
        return usedInMb

    }

    return 0
}

struct Math {
    static func stdDev(_ array: [Double]) -> Double {
        let mean = array.reduce(0, +) / Double(array.count)
        let variance = array.reduce(0) { $0 + pow($1 - mean, 2) } / Double(array.count)
        return sqrt(variance)
    }
}

extension String {
    func slugify() -> String {
        return
            self
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

// Create a new decoder everytime. Otherwise data is kept in memory
func createDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}

func createEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}
