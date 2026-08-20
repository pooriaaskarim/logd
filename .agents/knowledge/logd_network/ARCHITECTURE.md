# logd_network — Architecture & Design

---

## 1. Role in the Monorepo

`logd_network` is a first-party satellite package designed to decouple external networking dependencies (`package:http`, `package:web_socket_channel`) from the core `logd` logging engine.

```
┌──────────────────────────────────────────────────────────┐
│                      packages/logd                       │
│  - Semantic IR (LogDocument, LogNode)                    │
│  - Hierarchical Config & Versioned Cache Invalidation    │
│  - Execution Engines (StandardEngine, Arena, Native)     │
│  - Core Sinks (ConsoleSink, FileSink, MemorySink)        │
└──────────────────────────┬───────────────────────────────┘
                           │
            ┌──────────────┴──────────────┐
            ▼                             ▼
┌───────────────────────────┐ ┌───────────────────────────┐
│   packages/logd_network   │ │    packages/logd_sqlite   │
│ - HttpSink                │ │ - SqliteSink              │
│ - SocketSink              │ │ - SqliteHandler           │
│ - HttpServerSink          │ │ - WAL query engine        │
│ - HttpDashboardHandler    │ └───────────────────────────┘
│ - Serialization Registry  │
└───────────────────────────┘
```

---

## 2. Sink vs TargetHandler Boundary

- **`HttpServerSink`** (`LogSink<Uint8List>`):
  Low-level transport and server manager. Binds HTTP/WS server, serves HTML, and broadcasts raw bytes to WebSocket subscribers.
- **`HttpDashboardHandler`** (`Handler`):
  High-level pre-wired target handler. Pre-wires `StructuredFormatter`, `HtmlEncoder`, and `HttpServerSink` for instant zero-boilerplate local browser debugging.

---

## 3. Resilience & Backoff

- **Batching**: `HttpSink` buffers log entries up to `batchSize` or flushes periodically on `flushInterval`.
- **Exponential Backoff**: `HttpSink` and `SocketSink` handle network disconnects using exponential backoff retry algorithms with capped max delays.
- **Drop Policy**: Configurable `DropPolicy` (`discardOldest`, `discardNewest`) protects application memory when remote endpoints are unreachable.
