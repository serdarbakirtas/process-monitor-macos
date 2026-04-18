using Grpc.Net.Client;
using Processmonitor;

// Connect to Server
using var channel = GrpcChannel.ForAddress("http://localhost:50051");
var client = new ProcessMonitor.ProcessMonitorClient(channel);

Console.WriteLine("Connected to ProcessServer. Fetching processes every 5 seconds...\n");

// Fetch the process list every 5 seconds.
while (true)
{
    var response = await client.GetProcessesAsync(new ProcessRequest());

    Console.Clear();
    Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Top 10 Processes:\n");
    Console.WriteLine($"{"PID",-10} {"Name",-30}");
    Console.WriteLine(new string('-', 40));

    foreach (var process in response.Processes.Take(10))
    {
        Console.WriteLine($"{process.Pid,-10} {process.Name,-30}");
    }

    await Task.Delay(5000);
}