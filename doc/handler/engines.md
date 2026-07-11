# Execution Engines Guide

In `logd` version `0.8.0`, the logging pipeline's execution is delegated to exchangeable **LogEngines**. This allows developers to choose the optimal balance of memory safety, CPU overhead, and platform compatibility for their target application.

---

## The Three Engines

### 1. `StandardEngine` (Default)
The standard engine processes each log entry by creating a semantic object tree on the Dart VM garbage-collected heap.

*   **Platform Support**: 🟢 **Universal** (Runs on Android, iOS, macOS, Windows, Linux, and Web).
*   **Stability**: 🟢 **Excellent** (100% memory safe, zero risks of pointer issues or pool corruption).
*   **Layout Parity**: 🟢 **100%** (Fully compliant with the primary `TerminalLayout` implementation).
*   **Target Use Cases**: Mobile apps, web frontends, general-purpose microservices, and debugging pipelines.

---

### 2. `ArenaEngine`
The arena engine uses an isolate-local LIFO (Last In, First Out) object pool to recycle `LogDocument` and `LogNode` trees, reducing GC pressure to zero during steady-state logging.

*   **Platform Support**: 🟢 **Universal** (Web, VM, Flutter).
*   **Stability**: 🟡 **High** (Runs on safe Dart code, but expects formatters and decorators to not leak object references past the log cycle).
*   **Layout Parity**: 🟢 **100%** (Shares the exact same `TerminalLayout` physical rendering path).
*   **Target Use Cases**: High-throughput terminal logging where GC pauses must be avoided on the main thread.
*   **Safety Constraints & Bounds (v0.8.7+)**:
    *   **Unified Pool Cap**: To prevent unbounded memory expansion during heavy logging bursts, all internal object pools (AST nodes, collections, and maps) are strictly capped at `1000` items.
    *   **FIFO Waiter Queue**: High-throughput asynchronous calls waiting for pool capacity are resolved using a FIFO list queue, preventing race conditions or deadlocks under saturation.
    *   **Lazy Completion Port Lifecycle**: The background completion ReceivePort is lazily opened and cleanly closed on `clear()` or `disposeNative()` to prevent resource leaks.

---

### 3. `NativeEngine` (Opt-in)
The native engine serializes the formatted log snapshots directly into a language-agnostic **Binary Intermediate Representation (B-IR)** byte stream. On VM platforms, it can be opted into to offload both rendering and byte I/O to a background isolate worker.

*   **Platform Support**: 🟡 **VM-Only** (Requires `dart:ffi` and `dart:io`. **Does not compile on Web**).
*   **Stability**: 🟢 **Production Ready** (Fully stabilized and bounds-checked. Memory-safe dynamic LIFO pooling guarantees zero memory corruption or leaks).
*   **Layout Parity**: 🟢 **100% Parity** (Layout wrapping, padding, borders, and margins are mathematically verified against standard engine visual output across a matrix of 2,048 cases).
*   **Target Use Cases**: Performance-critical Command Line Interfaces (CLIs) and high-throughput server backends.

---

### 4. Isolate-Backed Pipeline Offloading (`AsyncHandler`)
While `NativeEngine` offloads B-IR snapshots using native FFI, `AsyncHandler` is a pure-Dart, VM-safe solution that offloads the entire standard logging pipeline (formatting, decorating, and writing to the sink) to a background isolate worker.

*   **Platform Support**: 🟢 **VM-Only** (Falls back to synchronous main-thread execution on Web).
*   **Stability**: 🟢 **Excellent** (Built on safe Dart standard libraries, fully isolated).
*   **Layout Parity**: 🟢 **100%** (Runs the exact same formatter/decorator pipeline inside the worker isolate).
*   **Target Use Cases**: Mobile/server environments where logging execution latency must be zero on the main application isolate, without relying on native FFI libraries.

---

## How-To Configuration Examples

### A. Configuring the default `StandardEngine` (Explicitly)
By default, `Handler` uses `StandardEngine`. You can configure it explicitly as follows:

```dart
final consoleHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: const [
    BoxDecorator(),
    StyleDecorator(),
  ],
  sink: const ConsoleSink(),
  engine: const StandardEngine(), // Default
);

Logger.configure('global', handlers: [consoleHandler]);
```

### B. Configuring the `ArenaEngine` (Zero-GC Pool)
To eliminate GC pressure on the main thread while maintaining 100% layout safety:

```dart
final arenaHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: const [
    BoxDecorator(),
    StyleDecorator(),
  ],
  sink: const ConsoleSink(),
  engine: const ArenaEngine(), // Reuses AST nodes
);

Logger.configure('global', handlers: [arenaHandler]);
```

### C. Configuring the `NativeEngine` & Isolate Offloading
To offload both formatting and write operations to a background isolate worker thread for near-zero main-thread latency:

```dart
// NativeIsolateSink wraps your target sink and spawns the background worker
final nativeSink = NativeIsolateSink(
  const ConsoleSink(lineLength: 80),
);

final nativeHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: const [], // Best when decorators are empty to trigger fast-path
  sink: nativeSink,
  engine: const NativeEngine(),
);

Logger.configure('global', handlers: [nativeHandler]);
```

### D. Configuring Pure-Dart Isolate Offloading (`AsyncHandler`)
To offload formatting and write operations for a standard logging pipeline to a background isolate worker without FFI dependencies:

```dart
final asyncHandler = AsyncHandler(
  formatter: const StructuredFormatter(),
  decorators: const [
    BoxDecorator(),
    StyleDecorator(),
  ],
  sink: const ConsoleSink(),
);

Logger.configure('global', handlers: [asyncHandler]);
```

---

## Performance Benchmark Data
*Profiled using Dart SDK 3.12.0 (Linux x64) over 10,000 iterations per scenario on a level playing field.*

### 1. Plain Text (Compact)
*High-density plain text serialization.*
*   **Standard**: 16,971 ops/sec (85.0µs)
*   **Arena**: **23,918 ops/sec** (61.0µs) 🏆
*   **Native**: 14,498 ops/sec (99.0µs)

### 2. Modern Human (Structured + Box)
*Standard terminal layout with borders.*
*   **Standard**: 9,157 ops/sec (166.0µs)
*   **Arena**: 9,638 ops/sec (157.0µs)
*   **Native**: **10,528 ops/sec** (124.0µs) 🏆

### 3. Framing Squeeze (Prefix + Box @ 40 width)
*Heavy word-wrapping and border drawing under tight constraints.*
*   **Standard**: 4,240 ops/sec (366.0µs)
*   **Arena**: 4,815 ops/sec (266.0µs)
*   **Native**: **6,442 ops/sec** (180.0µs) 🏆 *(1.5x speedup due to off-heap native wrapping)*

### 4. Complex Fallback (TOON + Box + Nesting)
*Complex format with decorators triggering compatibility fallback.*
*   **Standard**: 5,248 ops/sec (231.0µs)
*   **Arena**: **5,570 ops/sec** (211.0µs) 🏆
*   **Native**: 4,399 ops/sec (320.0µs) *(Lower throughput due to double-formatting fallback)*


---

## Long-Term Perspective & Tradeoffs
*   **Opt for Safety First**: For production application builds on multi-platform architectures (especially Web and Mobile), always stick with `StandardEngine`.
*   **GC Reduction**: For CLI logs in production servers, `ArenaEngine` offers a free throughput boost (~10-40%) without any platform-dependent risks.
*   **Future of NativeEngine**: With B-IR v2 serialization and layout parity fully completed in `v0.8.1`, `NativeEngine` is on track to be compiled into standalone C-libraries to support other languages (like Rust/Go/Python) using the exact same visual formatting specs of the Dart pipeline.

---

## Detailed Performance Analysis
For a deep-dive architectural assessment of the memory lifecycles (including detailed Mermaid flowcharts) and comparative scorecard metrics for each engine, see the [Logd Engine Stability & Performance Report](../engine_stability_report.md).
