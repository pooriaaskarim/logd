# Changelog

## 0.1.2

- **Web & WASM Compatibility**:
  - Replaced `dart:io` `HttpException` with `http.ClientException` in `HttpSink` to enable full Web and WASM runtime compatibility across browser targets (restoring 20/20 platform support score).
- **Example Tab Discovery Fix**:
  - Updated `example/main.dart` to contain the clean production usage showcase (`HttpDashboardHandler` + `HttpSink`) so pub.dev's Example tab renders the production example directly.
  - Moved interactive CLI menu gallery runner to `example/showcase_gallery.dart`.
  - Hidden deprecated core network exports in examples to prevent shadow analyzer warnings.

## 0.1.1

- **Pub.dev Score & Example Fixes**:
  - Hide deprecated core network exports in `example/example.dart` to resolve analyzer deprecation warnings.
  - Added `example/example.dart` standard example entrypoint for automated pub score discovery.
  - Added `platforms` metadata (`android`, `ios`, `linux`, `macos`, `web`, `windows`) and pub `topics` tags for 100% pub.dev score.

## 0.1.0

- Initial release of `logd_network`, a dedicated satellite package providing HTTP telemetry, WebSocket streaming, and embedded browser dashboards for `logd`.
- **`HttpSink`**: High-performance HTTP log collector sink supporting:
  - In-memory log entry batching (`batchSize`, `flushInterval`).
  - Exponential backoff retry algorithm with configurable max attempts (`maxRetries`).
  - Configurable drop policies (`DropPolicy.discardOldest`, `DropPolicy.discardNewest`) to prevent memory leaks during endpoint outages.
  - Custom HTTP headers and authorization token support.
- **`SocketSink`**: Real-time WebSocket streaming sink supporting:
  - Frame-by-frame live streaming over `ws://` and `wss://`.
  - Automatic reconnection logic with configurable `reconnectInterval`.
  - Offline log buffering during network downtime and atomic flush upon reconnection.
- **`HttpServerSink`**: Embedded local server sink supporting:
  - Loopback HTTP and WebSocket server hosting on configurable ports (`address`, `port`).
  - Embedded single-page browser dashboard UI with real-time WebSocket log streaming.
  - In-memory ring buffer (`bufferCapacity`) to replay past log history to new browser connections.
- **`HttpDashboardHandler`**: ADR-006 compliant pre-wired `Handler` subclass:
  - Zero-configuration plug-and-play setup for local browser log monitoring.
  - Pre-wires `StructuredFormatter`, `HtmlEncoder`, and `HttpServerSink` out of the box.
- **Cross-Isolate Serialization**:
  - `registerLogdNetworkSerializers()` helper for registering deserializers with `LoggerSerializationRegistry` in background worker isolates.
- **Interactive Showcases & Test Harness**:
  - Interactive CLI showcase gallery in `example/main.dart` with 4 dedicated showcases (`http_sink_showcase.dart`, `socket_sink_showcase.dart`, `http_server_sink_showcase.dart`, `http_dashboard_showcase.dart`).
  - Comprehensive unit and integration test suite (17/17 tests passing).
