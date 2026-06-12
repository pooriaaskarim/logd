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

---

### 3. `NativeEngine` (Experimental / Work in Progress)
The native engine serializes the formatted log snapshots directly into a language-agnostic **Binary Intermediate Representation (B-IR)** byte stream. On VM platforms, it can offload both rendering and byte I/O to a background isolate worker.

*   **Platform Support**: 🔴 **VM-Only** (Requires `dart:ffi` and `dart:io`. **Does not compile on Web**).
*   **Stability**: 🔴 **Experimental** (Under active stabilization. FFI pointer offset mistakes can lead to segmentation faults or memory leaks).
*   **Layout Parity**: 🟡 **Work in Progress** (Uses native FFI-based `BinaryAnsiEncoder` which must replicate Dart's wrapping geometry rules).
*   **Target Use Cases**: Performance-critical Command Line Interfaces (CLIs) and high-throughput server backends.

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

### C. Configuring the `NativeEngine` & Isolate Offloading (Experimental)
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

---

## Performance Benchmark Data
*Captured on Dart SDK 3.12.0 (Linux x64) over 10,000 iterations per scenario.*

### 1. Raw Machine (JSON)
*High-density JSON serialization.*
*   **Standard**: 14,155 ops/sec (97.0µs)
*   **Arena**: 20,265 ops/sec (63.0µs)
*   **Native**: **23,114 ops/sec** (64.0µs) 🏆

### 2. Modern Human (Structured + Box)
*Standard terminal layout with borders.*
*   **Standard**: 9,397 ops/sec (143.0µs)
*   **Arena**: 10,299 ops/sec (124.0µs)
*   **Native**: **13,284 ops/sec** (104.0µs) 🏆

### 3. Framing Squeeze (Prefix + Box @ 40 width)
*Heavy word-wrapping and border drawing under tight constraints.*
*   **Standard**: 4,670 ops/sec (280.0µs)
*   **Arena**: 4,931 ops/sec (249.0µs)
*   **Native**: **12,747 ops/sec** (100.0µs) 🏆 *(2.7x speedup due to off-heap native wrapping)*

### 4. Complex Fallback (TOON + Box + Nesting)
*Complex format with decorators triggering compatibility fallback.*
*   **Standard**: 5,248 ops/sec (231.0µs)
*   **Arena**: **5,570 ops/sec** (211.0µs) 🏆
*   **Native**: 4,399 ops/sec (320.0µs) *(Lower throughput due to double-formatting fallback)*

---

## Long-Term Perspective & Tradeoffs
*   **Opt for Safety First**: For production application builds on multi-platform architectures (especially Web and Mobile), always stick with `StandardEngine`.
*   **GC Reduction**: For CLI logs in production servers, `ArenaEngine` offers a free throughput boost (~10-40%) without any platform-dependent risks.
*   **Future of NativeEngine**: Once B-IR v2 serialization and layout stabilization are fully completed, `NativeEngine` is planned to be compiled into standalone C-libraries to support other languages (like Rust/Go/Python) using the exact same visual formatting specs of the Dart pipeline.

---

## Detailed Performance Analysis
For a deep-dive architectural assessment of the memory lifecycles (including detailed Mermaid flowcharts) and comparative scorecard metrics for each engine, see the [Logd Engine Stability & Performance Report](../engine_stability_report.md).
