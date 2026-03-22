//
//  Utils.swift
//  bap-swift
//
//  Created by Jan Lecoutere on 22/03/2026.
//

import Foundation

// Source - https://stackoverflow.com/a/64738201
// Posted by user1300214
// Retrieved 2026-03-22, License - CC BY-SA 4.0

func reportMemory() -> Float {
    var taskInfo = task_vm_info_data_t()
//    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
//    let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
//        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
//            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
//        }
//    }
    let usedMb = Float(taskInfo.phys_footprint) / 1048576.0
    return usedMb
}

struct Math {
    static func stdDev(_ array: [Double]) -> Double {
        let mean = array.reduce(0, +) / Double(array.count)
        let variance = array.reduce(0) { $0 + pow($1 - mean, 2) } / Double(array.count)
        return sqrt(variance)
    }
}
