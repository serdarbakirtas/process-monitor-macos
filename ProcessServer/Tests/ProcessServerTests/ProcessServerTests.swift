//
//  ProcessServerTests.swift
//  ProcessServer
//
//  Created by Hasan on 19.04.26.
//

import XCTest

final class ProcessServerTests: XCTestCase {

    // Test 1: Process list should not be empty
    func testProcessListIsNotEmpty() {
        let processes = collectProcesses()
        XCTAssertFalse(processes.isEmpty, "Process list should not be empty")
    }

    // Test 2: Each process must have a valid PID (Process ID).
    func testAllProcessesHaveValidPID() {
        let processes = collectProcesses()
        for process in processes {
            XCTAssertGreaterThan(process.pid, 0, "PID should be greater than 0")
        }
    }

    // Test 3:  Each process must have a name
    func testAllProcessesHaveNames() {
        let processes = collectProcesses()
        for process in processes {
            XCTAssertFalse(process.name.isEmpty, "Process name should not be empty")
        }
    }

    // Test 4: The core process (PID 0) should not be in the list.
    func testKernelProcessIsExcluded() {
        let processes = collectProcesses()
        let kernelProcess = processes.first { $0.pid == 0 }
        XCTAssertNil(kernelProcess, "Kernel process (PID 0) should be excluded")
    }

    // Test 5: The current process (test runner) should be listed.
    func testCurrentProcessIsPresent() {
        let processes = collectProcesses()
        let currentPID = Int32(ProcessInfo.processInfo.processIdentifier)
        let found = processes.first { $0.pid == currentPID }
        XCTAssertNotNil(found, "Current process should be in the list")
    }
}

struct ProcessItem {
    let name: String
    let pid: Int32
}

func collectProcesses() -> [ProcessItem] {
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
    var size = 0

    sysctl(&mib, 4, nil, &size, nil, 0)

    let count = size / MemoryLayout<kinfo_proc>.stride
    var procs = [kinfo_proc](repeating: kinfo_proc(), count: count)
    sysctl(&mib, 4, &procs, &size, nil, 0)

    return procs.compactMap { proc in
        let pid = proc.kp_proc.p_pid
        guard pid > 0 else { return nil }

        let name = withUnsafeBytes(of: proc.kp_proc.p_comm) { buf in
            String(bytes: buf.prefix(while: { $0 != 0 }), encoding: .utf8) ?? "unknown"
        }

        return ProcessItem(name: name, pid: pid)
    }
}
