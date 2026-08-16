# Isolate Offloading (`AsyncHandler`) & Concurrency Guide

`logd` provides isolate offloading to transfer the entire logging pipeline—formatting, decorating, layout calculation, and physical sinking—to a background worker isolate.

---

## 1. Idiomatic Path: Zero-Config `.async()` Constructors (v0.9.3+)

For all output-bound file and console logging, you do not need to manually construct `AsyncHandler`. Simply use the `.async()` factory constructor on the corresponding `{Target}Handler`:

```dart
import 'package:logd/logd.dart';

// Terminal logging on background isolate
final console = ConsoleHandler.async();

// File logging on background isolate
final jsonLogs = JsonFileHandler.async('logs/production.json');
final htmlReport = HtmlFileHandler.async('logs/report.html');
final toonLogs = ToonFileHandler.async('logs/telemetry.toon');
final plainLogs = PlainFileHandler.async('logs/app.log');
final markdown = MarkdownFileHandler.async('logs/summary.md');

Logger.configure('app', handlers: [console, jsonLogs]);
```

---

## 2. Advanced Path: Raw `AsyncHandler` (package:logd/advanced.dart)

When composing custom formatters, decorators, or multi-sinks on a background isolate, import `package:logd/advanced.dart`:

```dart
import 'package:logd/advanced.dart';
import 'package:logd/logd.dart';

final customAsyncHandler = AsyncHandler(
  formatter: const JsonFormatter(),
  decorators: const [StyleDecorator()],
  sink: FileSink('logs/custom.json'),
);
```

---

## 3. When to Use Background Isolate Offloading

| Scenario | Recommendation | Rationale |
|---|---|---|
| High-volume CLI logging | Sync `ConsoleHandler()` | Synchronous console output is fast; isolate thread context switches add minor latency overhead (~15µs). |
| Flutter UI applications | `ConsoleHandler.async()` / `JsonFileHandler.async()` | Offloads formatting & disk I/O completely off the UI thread to guarantee 0 dropped frames (60/120 fps). |
| Heavy JSON / HTML serialization | `JsonFileHandler.async()` / `HtmlFileHandler.async()` | Offloads CPU-intensive encoding away from the main UI / event-loop thread. |
| In-memory testing / Ring-buffers | `MemoryHandler()` | In-memory sinks require zero I/O, run inline, and keep `.entries` on the caller isolate heap. |

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
