# logd_network — Status
> Current as of: logd_network v0.1.0 | Updated: 2026-08-20

---

## Release State

| Milestone | Status |
|---|---|
| v0.1.0 — Satellite Package Scaffolding | ✅ Complete |
| Source extraction (`HttpSink`, `SocketSink`, `HttpServerSink`, `HttpDashboardHandler`) | ✅ Complete |
| Standalone unit & live integration test suites (17/17 passing) | ✅ Complete |
| Interactive & standalone CLI examples gallery (`example/main.dart` + `example/showcase/`) | ✅ Complete |
| Cross-isolate serialization registry hook (`registerLogdNetworkSerializers()`) | ✅ Complete |
| Core soft deprecations (`@Deprecated` targeting v0.10.0) | ✅ Complete |
| ADR-007 and migration documentation persisted | ✅ Complete |
| v0.1.0 — Pub.dev Publishing | 🔲 Pending release |

---

## Component Inventory

| Component | Category | Description |
|---|---|---|
| `HttpSink` | Physical Sink | Accumulates logs in memory and posts in batches via HTTP with exponential backoff retry. |
| `SocketSink` | Physical Sink | Streams logs frame-by-frame over WebSockets with auto-reconnection and buffering. |
| `HttpServerSink` | Physical Sink | Hosts a local HTTP + WebSocket server streaming encoded logs to browser clients. |
| `HttpDashboardHandler` | TargetHandler | Pre-wired convenience handler combining `StructuredFormatter`, `HtmlEncoder`, and `HttpServerSink`. |
| `registerLogdNetworkSerializers()` | Serialization | Registers `HttpSink` and `SocketSink` deserializers with `LoggerSerializationRegistry`. |

---

## Known Traps & Invariants

- **Isolate Deserialization**: Worker isolates must execute `registerLogdNetworkSerializers()` before calling `Logger.importConfig()`.
- **Encapsulation Boundary**: Subclasses of `EncodingSink` rely on `@protected isPreambleWritten` from core to manage document-level preambles.
- **Example Subprocesses**: Showcase scripts dynamically resolve the repository root and dedicated `.venv/bin/python` binary for Python mock servers.
