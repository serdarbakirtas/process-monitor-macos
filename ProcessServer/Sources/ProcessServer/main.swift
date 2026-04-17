import GRPC
import NIOCore
import NIOPosix
import Foundation

final class ProcessMonitorService: Processmonitor_ProcessMonitorAsyncProvider {
    let interceptors: Processmonitor_ProcessMonitorServerInterceptorFactoryProtocol? = nil

    func getProcesses(
        request: Processmonitor_ProcessRequest,
        context: GRPCAsyncServerCallContext
    ) async throws -> Processmonitor_ProcessResponse {

        var response = Processmonitor_ProcessResponse()
        response.processes = collectProcesses()
        return response
    }

    private func collectProcesses() -> [Processmonitor_ProcessInfo] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0

        sysctl(&mib, 4, nil, &size, nil, 0)

        let count = size / MemoryLayout<kinfo_proc>.stride
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count)
        sysctl(&mib, 4, &procs, &size, nil, 0)

        return procs.compactMap { proc in
            let pid = proc.kp_proc.p_pid
            guard pid > 0 else { return nil }

            var name = withUnsafeBytes(of: proc.kp_proc.p_comm) { buf in
                String(bytes: buf.prefix(while: { $0 != 0 }), encoding: .utf8) ?? "unknown"
            }

            var info = Processmonitor_ProcessInfo()
            info.pid = pid
            info.name = name
            return info
        }
    }
}

// Start Server
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

let server = try await Server.insecure(group: group)
    .withServiceProviders([ProcessMonitorService()])
    .bind(host: "localhost", port: 50051)
    .get()

print("ProcessServer started on port 50051")

try await server.onClose.get()
