# Isolate Offloading (`AsyncHandler`) & Concurrency Guide

`logd` provides `AsyncHandler` to offload the entire logging pipeline—formatting, decorating, layout calculation, and physical sinking—to a background worker isolate.

---

## 1. When to Use `AsyncHandler`

| Scenario | Recommendation | Rationale |
|---|---|---|
| High-volume CLI logging | `StandardEngine` | Synchronous console output is fast; isolate thread context switches add minor latency overhead (~15µs). |
| Heavy JSON / HTML serialization | `AsyncHandler` | Offloads CPU-intensive encoding away from the main UI / event-loop thread. |
| Slow physical sinks (File, Network, HTTP Viewer) | `AsyncHandler` | Main thread returns immediately (~15–20µs); physical disk/network I/O happens asynchronously on the background worker. |
| In-memory testing | `StandardEngine` | In-memory sinks require zero I/O and run instantaneously inline. |

---

## 2. Architecture & Lifecycle

When instantiated, `AsyncHandler` spawns a background worker isolate via `IsolateWorker`:

```
Main Isolate                      Background Isolate
[Logger.info()]                   [IsolateWorker]
      │                                  │
      ├── SendPort.send(LogEntry) ─────► │ [Formatter]
      │                                  ├──► [Decorator]
      ▼ (returns in ~15µs)               └──► [LogSink.output()]
```

### Lifecyle Requirements

1. **Wait for startup (`await handler.ready`)**:
   When launching background workers during initial application setup, optionally await `handler.ready` to guarantee port allocation before sending initial logs:
   ```bash
   final handler = AsyncHandler(
     formatter: const JsonFormatter(),
     sink: FileSink(path: 'app.log'),
   );
   await handler.ready;
   ```

2. **Graceful Teardown (`await handler.dispose()`)**:
   Always dispose handlers when shutting down services or completing isolate workers:
   ```dart
   await handler.dispose();
   ```
   `dispose()` flushes pending worker queues, disposes of child sinks, and safely terminates the worker isolate to prevent memory or file handle leaks.

---

## 3. Serialization Constraints

Because `AsyncHandler` transfers objects across `SendPort` boundaries:
- All custom `formatter`, `decorators`, and `sink` instances passed to `AsyncHandler` must be sendable across Dart isolate boundaries (preferably `@immutable` with `const` constructors).
- Sinks containing non-transferable native assets or open socket streams must manage isolate-aware setup within worker isolates.
