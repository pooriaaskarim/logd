# `LogBuffer` Memory Pooling & Lifecycle Guide

`LogBuffer` provides an efficient, string-sink interface for constructing multi-line log messages before atomic flushing to the underlying `Logger`.

---

## 1. Pool Architecture

To minimize GC allocation churn during burst logging (e.g. concurrent HTTP request handling), `LogBuffer` uses an internal no-config LIFO object pool:

```
checkout() ──► Pool Has Buffers? ──YES──► Reuse & Reset Instance
                    │
                   NO
                    ▼
            Instantiate New Handle + Body
```

- **Default Pool Capacity (`_maxPoolSize = 32`)**: Sized to cover typical concurrent burst logging without accumulating excessive memory.
- **Eviction**: Idle instances beyond `_maxPoolSize` are discarded and collected naturally by Dart GC.

---

## 2. Buffer Lifecycle & Leak Protection

Every `LogBuffer` instance is composed of a light **Handle** (`LogBuffer`) attached to a persistent **Body** (`_LogBuffer`).

```dart
final buf = logger.infoBuffer;
buf?.writeln('Step 1');
buf?.writeln('Step 2');
buf?.sink(); // Flushes log to logger and recycles buffer to pool
```

### Abandoned Buffer Leak Warnings (`Finalizer`)

If a buffer is created but never explicitly sunk via `.sink()`, Dart's garbage collector will eventually sweep the unreferenced handle. An internal `Finalizer` intercepts garbage collection and takes protective action based on `autoSinkBuffer`:

| `autoSinkBuffer` Config | Result on Abandoned Buffer |
|---|---|
| `false` (default) | Logs a severe `InternalLogger` warning; **buffer data is dropped** to enforce explicit lifecycle hygiene. |
| `true` | Automatically flushes accumulated buffer contents to `Logger` and logs a warning. |

---

## 3. `maxEntries` Memory Growth Safeguards

When constructing long or dynamically generated multi-line logs, pass `maxEntries` to cap memory growth in case a loop produces unbounded output:

```dart
final buf = logger.buffer(LogLevel.info, maxEntries: 100);

for (var item in dynamicItems) {
  buf?.writeln(item); // Excess items past 100 are dropped with a warning
}

buf?.sink();
```

When `maxEntries` is reached:
1. `writeln` ignores further text insertions.
2. `InternalLogger` emits a single rate-limited warning indicating entry truncation.
3. Flushing via `.sink()` outputs the truncated content safely.

---

## 4. GC Pressure Guidance

For high-throughput HTTP servers or streaming pipelines:
- Prefer `logger.buffer(level)` over constructing custom `StringBuffer` objects.
- Always call `buf.sink()` inside `finally` blocks if exception paths exist:
  ```dart
  final buf = logger.infoBuffer;
  try {
    buf?.writeln('Processing...');
  } finally {
    buf?.sink();
  }
  ```
