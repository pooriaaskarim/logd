# Cross-Isolate Logger Coordination Guide

In Dart, memory is not shared between isolates; each isolate has its own independent heap, global state, and static variables. Consequently, **`logd` logger configurations are isolate-local by default**. 

If you configure a logger (e.g., setting its log level or adding custom sinks) in the main isolate, these settings **will not** propagate automatically to background worker isolates.

To solve this, `logd` provides a robust, built-in serialization and transport layer. This guide details how to synchronize logger configurations across isolates, register custom components, and dynamically coordinate settings.

---

## 1. Basic Isolate Transport

`logd` supports exporting the entire configuration tree from one isolate and importing it into another using JSON-compatible maps:

```dart
// 1. In the Main Isolate:
// Export a snapshot of the current configurations (including pattern rules)
final Map<String, dynamic> configSnapshot = Logger.exportConfig();

// Pass `configSnapshot` as part of the initial message to the worker isolate.
Isolate.spawn(workerEntryPoint, configSnapshot);
```

```dart
// 2. In the Worker Isolate:
void workerEntryPoint(Map<String, dynamic> configSnapshot) {
  // Import the configurations in the background isolate
  Logger.importConfig(configSnapshot);

  // Now, the worker's loggers match the main isolate's configurations exactly
  Logger.get('app.service').info('Worker initialized and configured!');
}
```

---

## 2. Syncing Custom Components (`LoggerSerializationRegistry`)

When configurations are exported and imported, `logd` serializes the logging pipeline components (Sinks, Formatters, Filters, Decorators, and Engines) into JSON specs.

Out of the box, `logd` automatically registers all built-in components (e.g., `ConsoleSink`, `FileSink`, `PlainFormatter`, `BoxDecorator`, `LevelFilter`, etc.). If your loggers use custom implementations of these components, you **must** register serializer/deserializer specs in both the main and worker isolates before exporting/importing configuration.

### Custom Component Registration Example

```dart
import 'package:logd/logd.dart';

// A custom log sink that forwards entries to a remote telemetry API
class TelemetrySink extends LogSink<LogDocument> {
  final String apiEndpoint;

  const TelemetrySink({required this.apiEndpoint});

  @override
  Future<void> output(
    LogDocument document,
    LogEntry entry,
    LogLevel level,
    LogPipelineFactory factory,
  ) async {
    // Custom shipping logic...
  }
}

// Register the custom TelemetrySink for cross-isolate serialization
void registerCustomComponents() {
  LoggerSerializationRegistry.registerSink<TelemetrySink>(
    type: 'TelemetrySink',
    fromJson: (final json) => TelemetrySink(
      apiEndpoint: json['apiEndpoint'] as String,
    ),
    toJson: (final val) => <String, dynamic>{
      'apiEndpoint': val.apiEndpoint,
    },
  );
}
```

> [!IMPORTANT]
> Call `registerCustomComponents()` at the very beginning of the program in **both** the spawning (main) and spawned (worker) isolates.

---

## 3. Dynamic Configuration Synchronization

In long-running applications, logger configurations might change dynamically (e.g., when a user turns on debug logging via an admin dashboard). You can push these updates from the main isolate to worker isolates over a `SendPort`.

### Complete Coordination Example

Here is a copy-pasteable, end-to-end example demonstrating launching a worker, initializing its configuration, and sending dynamic level updates during runtime:

```dart
import 'dart:async';
import 'dart:isolate';
import 'package:logd/logd.dart';

/// Message contract to pass configuration snapshots and updates
class IsolateCommand {
  final String action;
  final Map<String, dynamic> payload;

  const IsolateCommand({required this.action, required this.payload});
}

void main() async {
  // 1. Configure the main isolate loggers
  Logger.configure('app', logLevel: LogLevel.info);
  
  final mainLogger = Logger.get('app.main');
  mainLogger.info('Main isolate starting worker...');

  // 2. Setup ports for communication
  final receivePort = ReceivePort();
  
  // Export initial config tree
  final initialConfig = Logger.exportConfig();
  
  // Spawn the worker and pass the send port & initial config
  final workerIsolate = await Isolate.spawn(
    workerEntryPoint,
    [receivePort.sendPort, initialConfig],
  );

  // Wait for the worker to send its Command Port
  final completer = Completer<SendPort>();
  receivePort.listen((final message) {
    if (message is SendPort) {
      completer.complete(message);
    } else {
      mainLogger.info('Received from worker: $message');
    }
  });

  final workerCommandPort = await completer.future;

  // 3. Simulate dynamic config updates in the Main Isolate
  await Future.delayed(const Duration(seconds: 1));
  mainLogger.info('Main Isolate: Raising logging level of "app" to warning...');
  
  // Update configuration locally
  Logger.configure('app', logLevel: LogLevel.warning);
  
  // Send the updated config tree to the worker isolate
  workerCommandPort.send(IsolateCommand(
    action: 'update_config',
    payload: Logger.exportConfig(),
  ));

  // Clean up after work is done
  await Future.delayed(const Duration(seconds: 1));
  workerIsolate.kill(priority: Isolate.beforeNextEvent);
  receivePort.close();
}

/// Entry point for the worker isolate
void workerEntryPoint(List<dynamic> initArgs) {
  final SendPort mainSendPort = initArgs[0];
  final Map<String, dynamic> initialConfig = initArgs[1];

  // 1. Initialize logd with inherited config from Main Isolate
  Logger.importConfig(initialConfig);
  final workerLogger = Logger.get('app.worker');
  
  workerLogger.info('Worker: Initialized (this message will print)');

  // 2. Setup a command port to receive dynamic config updates
  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  commandPort.listen((final message) {
    if (message is IsolateCommand && message.action == 'update_config') {
      // Apply the updated config snapshot dynamically
      Logger.importConfig(message.payload);
      
      // Let main isolate know the update is applied
      mainSendPort.send('Worker: Applied config update.');
      
      // Test the new config. (If level was raised to warning, this info log won't print)
      workerLogger.info('Worker: This should not print if level is warning');
      workerLogger.warning('Worker: This warning WILL print!');
    }
  });
}
```

---

## 4. Best Practices

* **Batch Updates**: Only send updates when configuration changes occur (avoid querying `exportConfig()` in tight loops).
* **Resetting Before Import**: While `Logger.importConfig` overwrites configurations in-place, it is best practice to run `Logger.reset()` globally in the worker before importing if you want to ensure a clean, absolute state synchronization.
* **Avoid Nested Isolate Sinks**: If your background isolate needs to write logs, it is often more performant to send logs back to the main isolate via `IsolateSink` rather than performing expensive I/O operations (like file writes) concurrently from multiple isolates.
