# ADR-007: Satellite Package Architecture for Domain-Specific Sinks & Handlers

## Status
Accepted (v0.9.5)

## Context
The core `logd` logging engine was initially packaged with several network-related sinks and handlers (`HttpSink`, `SocketSink`, `HttpServerSink`, `HttpDashboardHandler`). This forced `packages/logd` to declare direct dependencies on `package:http` and `package:web_socket_channel`.

However, as `logd` evolves toward a zero-overhead, hyper-optimized core:
1. Pure CLI, microservice, or desktop Flutter applications that only require console, memory, or file logging were paying the dependency graph cost and version resolution constraints of networking packages.
2. The core package should focus exclusively on semantic IR (`LogDocument`), hierarchical configuration resolution, execution engines (`StandardEngine`, `ArenaEngine`, `NativeEngine`), and physical ANSI/file layout.
3. Satellite packages (like `logd_sqlite` and `logd_linters`) have demonstrated the superiority of a modular monorepo architecture.

## Decision
1. **Extract `packages/logd_network`**:
   - Move `HttpSink`, `SocketSink`, `NetworkSink`, `DropPolicy`, `HttpServerSink`, and `HttpDashboardHandler` into the `logd_network` satellite package.
   - `logd_network` depends on `logd`, `http`, and `web_socket_channel`.
2. **Two-Phase Soft-Break Lifecycle**:
   - **Phase 1 (v0.9.5)**: Mark network classes in `packages/logd` as `@Deprecated('Use ... from package:logd_network instead. Will be removed in v0.10.0')`. Core examples and tests decouple from network dependencies.
   - **Phase 2 (v0.10.0)**: Permanently delete deprecated network files from `packages/logd` and remove `http` and `web_socket_channel` from core `pubspec.yaml`, achieving a zero-network-dependency core engine.
3. **Cross-Isolate Serialization Protocol**:
   - Satellite packages provide explicit serialization hooks (e.g. `registerLogdNetworkSerializers()`) that register their sink/handler deserializers with `LoggerSerializationRegistry` in worker isolates.
4. **Encapsulation Safeguard**:
   - Expose `isPreambleWritten` as `@protected` in `EncodingSink` to allow satellite sinks to manage their own preamble states without violating encapsulation boundaries.

## Consequences

### Positive
- **Lighter Core**: Core `logd` dependency footprint is minimized, preventing dependency version conflicts for users who do not need HTTP or WebSocket logging.
- **Independent Evolution**: Network transport, protocol retries, and dashboard UI capabilities can release and evolve without churning core releases.
- **Ecosystem Extensibility**: Establishes the standard blueprint for future community-driven sinks (e.g., `logd_sentry`, `logd_datadog`, `logd_grpc`).

### Negative / Trade-offs
- Users who need HTTP/WebSocket logging must add `logd_network` as an additional dependency.
- Background isolate logging with network sinks requires a one-time call to `registerLogdNetworkSerializers()`.
