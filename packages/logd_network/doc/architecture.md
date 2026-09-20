# logd_network Architecture

`logd_network` provides real-time network logging, HTTP batch ingesters, WebSocket streams, and live browser dashboard sinks for the `logd` logging ecosystem.

## Core Components

### 1. `HttpSink`
A batch-oriented `LogSink` that buffers log entries and POSTs them to a remote HTTP endpoint in JSON payload arrays:
- **Batching (`batchSize`, `flushInterval`)**: Reduces network latency and socket overhead.
- **Resilience**: Configurable exponential backoff retries (`maxRetries`) and memory buffer capacities (`maxBufferSize`, `dropPolicy`).

### 2. `SocketSink`
A WebSocket streaming `LogSink` that maintains a persistent connection (`wss://` or `ws://`) to stream log entries in real time with automatic reconnect capabilities (`reconnectInterval`).

### 3. `HttpServerSink` & `HttpDashboardHandler`
A self-contained HTTP/WebSocket server that hosts an interactive real-time HTML browser dashboard (`dashboard_html.dart`):
- Serves an inline single-page log viewer dashboard over HTTP GET `/`.
- Broadcasts formatted log entries over WebSocket (`ws://`).
- Buffers historical entries (`bufferCapacity`) so newly opened browser tabs immediately render past log entries.
- `HttpDashboardHandler.async(...)` allows running the dashboard server on a background Dart isolate.
