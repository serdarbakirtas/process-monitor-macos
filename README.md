# Process Monitor — macOS

A macOS application consisting of a background daemon (server) and a console client that displays currently running processes.

## Architecture

```
┌─────────────────────┐         gRPC / HTTP2        ┌─────────────────────┐
│   ProcessServer     │ ◄─────────────────────────► │   ProcessClient     │
│   (Swift Daemon)    │                              │   (C# Console App)  │
│                     │                              │                     │
│ • Unix daemon       │                              │ • Connects via gRPC │
│ • Collects processes│                              │ • Displays top 10   │
│ • gRPC server       │                              │ • Refreshes every 5s│
│   port: 50051       │                              │                     │
└─────────────────────┘                              └─────────────────────┘
```

## Requirements

- macOS 13+
- Xcode 15+ / Swift 5.9+
- .NET 10 SDK
- protobuf (`brew install protobuf`)
- gRPC tools (`brew install grpc`)

## Project Structure

```
process-monitor-macos/
├── proto/
│   └── process_monitor.proto     # gRPC service definition
├── ProcessServer/                # Swift daemon
│   ├── Package.swift
│   ├── dev.processmonitor.plist  # launchd daemon config
│   └── Sources/ProcessServer/
│       ├── main.swift
│       ├── process_monitor.pb.swift
│       └── process_monitor.grpc.swift
└── ProcessClient/                # C# console client
    ├── ProcessClient.csproj
    ├── Program.cs
    ├── ProcessMonitor.cs         # generated from proto
    └── ProcessMonitorGrpc.cs     # generated from proto
```

## Build & Run

### 1. Build the Server

```bash
cd ProcessServer
swift build -c release
```

### 2. Install and Start the Daemon

```bash
# Copy binary
sudo mkdir -p /usr/local/bin
sudo cp .build/release/ProcessServer /usr/local/bin/ProcessServer

# Register as daemon
sudo cp dev.processmonitor.plist /Library/LaunchDaemons/dev.processmonitor.plist
sudo launchctl load /Library/LaunchDaemons/dev.processmonitor.plist

# Verify daemon is running
sudo launchctl list | grep processmonitor
```

Expected output:
```
<PID>    0    dev.processmonitor
```

### 3. Build and Run the Client

```bash
cd ProcessClient
dotnet build
dotnet run
```

Expected output:
```
[02:14:35] Top 10 Processes:

PID        Name
----------------------------------------
1234       ProcessServer
1235       Finder
...
```

## Daemon Management

```bash
# Check logs
cat /tmp/processmonitor.log
cat /tmp/processmonitor.error.log

# Live logs
tail -f /tmp/processmonitor.log

# Stop daemon
sudo launchctl unload /Library/LaunchDaemons/dev.processmonitor.plist

# Restart daemon
sudo launchctl unload /Library/LaunchDaemons/dev.processmonitor.plist
sudo launchctl load /Library/LaunchDaemons/dev.processmonitor.plist
```

## Code Signing

Both binaries are signed:

**Server** — signed with Apple Development certificate:
```bash
codesign --sign "Apple Development: <your identity>" \
  --options runtime \
  .build/release/ProcessServer

# Verify
codesign --verify --verbose .build/release/ProcessServer
```

**Client** — automatically signed by Microsoft .NET SDK.

To find your signing identity:
```bash
security find-identity -v -p codesigning
```

## Communication Protocol

The client and server communicate via gRPC. The service is defined in `proto/process_monitor.proto`:

- `GetProcesses` — client requests the current process list, server responds with name and PID of all running processes.

## Notes

- The server uses `sysctl` to collect all running processes directly from the macOS kernel.
- The daemon is managed by `launchd` and starts automatically on system boot.
- The client refreshes the process list every 5 seconds.
