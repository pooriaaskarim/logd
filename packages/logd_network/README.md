# logd_network

[![pub package](https://img.shields.io/pub/v/logd_network.svg)](https://pub.dev/packages/logd_network)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Network-based sinks and live observability handlers for [`logd`](https://pub.dev/packages/logd).

Features HTTP batch shipping with exponential backoff retries, real-time WebSocket log streaming with automatic reconnection buffering, and an embedded local HTTP/WebSocket browser dashboard (`HttpDashboardHandler` / `HttpServerSink`).

---

## Installation

Add `logd` and `logd_network` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^latest_version
  logd_network: ^latest_version
```

---

## Quick Start

Use the pre-wired `HttpDashboardHandler` to host a local real-time browser logging dashboard with zero setup:

```dart
import 'package:logd/logd.dart';
import 'package:logd_network/logd_network.dart';

void main() {
  final dashboard = HttpDashboardHandler(
    port: 8080,
    title: 'Production Telemetry Stream',
    bufferCapacity: 200,
  );

  Logger.configure('app', handlers: [dashboard]);

  final logger = Logger.get('app.service');
  logger.info('Server started cleanly.');
  logger.warning('High memory pressure', context: {'usage': '87%'});

  // Open http://localhost:8080 in your browser to view logs in real time!
}
```

---

## Features & Component Overview

| Component | Type | Description |
|---|---|---|
| [`HttpDashboardHandler`](#1-httpdashboardhandler-embedded-browser-viewer) | TargetHandler | Pre-wired convenience handler for local browser log monitoring via HTTP/WebSocket. |
| [`HttpSink`](#2-httpsink-batch-shipping--exponential-retries) | Physical Sink | Accumulates logs in memory and ships in POST batches with exponential backoff retries. |
| [`SocketSink`](#3-socketsink-real-time-websocket-streaming) | Physical Sink | Streams logs frame-by-frame over WebSockets with offline reconnect buffering. |
| [`HttpServerSink`](#4-httpserversink-low-level-custom-dashboard-sink) | Physical Sink | Low-level server sink for hosting custom HTML/ANSI dashboards on custom ports. |

---

### 1. `HttpDashboardHandler` (Embedded Browser Viewer)
Pre-wired, zero-configuration handler that boots a lightweight local HTTP and WebSocket server hosting an interactive real-time log viewer.

```dart
final dashboard = HttpDashboardHandler(
  port: 8080,
  title: 'Real-Time Observability Dashboard',
);

Logger.configure('app', handlers: [dashboard]);
```

---

### 2. `HttpSink` (Batch Shipping & Exponential Retries)
Accumulates log entries in memory and posts them in batches to remote log aggregators (e.g. Datadog, Loggly, Vector, or custom HTTP ingestion endpoints).

```dart
final httpHandler = Handler(
  formatter: const JsonFormatter(),
  sink: HttpSink(
    url: 'https://logs.example.com/api/v1/ingest',
    headers: const {'Authorization': 'Bearer token-xyz'},
    batchSize: 50,
    flushInterval: const Duration(seconds: 30),
    maxRetries: 5,
    dropPolicy: DropPolicy.discardOldest,
  ),
);

Logger.configure('app', handlers: [httpHandler]);
```

**Drop Policies:**
- `DropPolicy.discardOldest`: Evicts the oldest buffered entry when capacity is reached.
- `DropPolicy.discardNewest`: Rejects incoming entries when buffer is full.

---

### 3. `SocketSink` (Real-Time WebSocket Streaming)
Streams logs frame-by-frame over WebSockets with automatic reconnection and offline buffering.

```dart
final wsHandler = Handler(
  formatter: const PlainFormatter(metadata: {LogMetadata.timestamp, LogMetadata.logger}),
  decorators: const [StyleDecorator(), BoxDecorator()],
  sink: SocketSink(
    url: 'wss://stream.example.com/live-logs',
    reconnectInterval: const Duration(seconds: 5),
  ),
);

Logger.configure('app.stream', handlers: [wsHandler]);
```

---

### 4. `HttpServerSink` (Low-Level Custom Dashboard Sink)
If you want to use custom formatters (like `ToonFormatter`), custom decorators, or custom encoders while hosting a local browser server, use `HttpServerSink` directly:

```dart
final serverSink = HttpServerSink(
  address: 'localhost',
  port: 8085,
  encoder: const HtmlEncoder(title: 'Custom Terminal Stream'),
  bufferCapacity: 500,
);

final customHandler = Handler(
  formatter: const ToonFormatter(),
  sink: serverSink,
);

Logger.configure('custom', handlers: [customHandler]);
```

---

## Cross-Isolate Serialization

If transferring logger configurations to background worker isolates via `Logger.exportConfig()` and `Logger.importConfig()`, register network serializers in the worker isolate before importing:

```dart
import 'package:logd/logd.dart';
import 'package:logd_network/logd_network.dart';

void workerIsolateEntry(SendPort sendPort) {
  // Register logd_network serializers
  registerLogdNetworkSerializers();

  // Import config passed from main isolate
  Logger.importConfig(exportedJson);
}
```

---

## Interactive CLI Examples Gallery

`logd_network` provides an interactive CLI showcase menu in `example/main.dart`:

```bash
# Run interactive CLI showcase menu
dart run example/main.dart

# Or run non-blocking automated summary
dart run example/main.dart 5
```

Or run individual standalone showcase scripts:

```bash
dart run example/showcase/http_sink_showcase.dart
dart run example/showcase/socket_sink_showcase.dart
dart run example/showcase/http_server_sink_showcase.dart
dart run example/showcase/http_dashboard_showcase.dart
```

---

## Documentation & Monorepo

For deep-dive documentation on `logd` architecture, migration guides, and execution engines:

- [**logd Monorepo Root**](https://github.com/pooriaaskarim/logd)
- [**Migration Guide (v0.9.5 Satellite Extraction)**](https://github.com/pooriaaskarim/logd/blob/master/doc/migration.md)
- [**ADR-007: Satellite Package Architecture**](https://github.com/pooriaaskarim/logd/blob/master/doc/decisions/adr-007-satellite-package-extraction.md)

---

## License

This package is licensed under the **BSD 3-Clause License**. See the [LICENSE](LICENSE) file for details.
