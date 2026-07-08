# logd Core — Architecture
> Stable reference. Core invariants, pipeline contract, and design rationale.
> Update only when a design decision is permanently resolved.

---

## The Pipeline Contract

```
LogEntry
  → LogFormatter        → LogDocument (Semantic IR tree)
  → LogDecorator(s)     → LogDocument (mutated in-place)
  → TerminalLayout      → PhysicalDocument (physical, camera-ready lines)
  → LogEncoder          → byte stream
  → LogSink             → output
```

### Invariants That Must Never Be Violated
1. **Formatters and Decorators operate on Semantic IR only.** They never touch terminal width, pixel measurements, or string rendering.
2. **`TerminalLayout` is the sole authority on physical layout.** Wrapping, tab-stops, ANSI segment slicing — all here, nowhere else.
3. **Engine parity must be maintained.** `StandardEngine` and `ArenaEngine` must produce byte-for-byte identical output for the same input. Verified by `engine_parity_test.dart`.
4. **`@immutable` on all Formatters, Decorators, and metadata configs.** These are shared across isolates. Mutable state = data race.

---

## Resource Model: `LogPipelineFactory`

All pipeline components are decoupled from memory strategy via injection:

```dart
abstract interface class LogPipelineFactory {
  LogDocument checkoutDocument();
  // ... all node types ...
  void release(Object obj);
}
```

- **`StandardEngine`**: Heap-allocated. GC-managed. Simple.
- **`ArenaEngine`**: LIFO object pool. Near-zero GC. Benchmarked at ~50% faster than standard heap for high-throughput paths.
- **`NativeEngine`**: Linearizes to Binary IR (B-IR). Two modes:
  - **Streaming Mode** (no decorators): Emitter API writes directly to `BinaryIRWriter`. Zero Dart object allocation.
  - **Object Mode** (decorators present): Builds `LogNode` tree, decorates, then linearizes.

### Arena Limits (v0.8.7)
- Object pool cap: **512 objects**
- Native buffer pool cap: **1000 buffers**
- Pre-ready packet buffer (IsolateSink startup): **200 packets**

---

## Logger Hierarchy & Configuration

### Sparse Registry
`Logger._registry` stores `LoggerConfig` sparsely — `null` fields mean "inherit from parent." Dot-separated names define hierarchy (e.g., `app.network.http` inherits from `app.network` → `app` → `global`).

### Cache Resolution (Fast/Slow Path Split)
- **Fast-path `_resolve()`**: `@pragma('vm:prefer-inline')`. Returns cached config if `cached.version == config._version`. Inlined by JIT.
- **Slow-path `_resolveSlow()`**: Walks the hierarchy, builds unmodifiable snapshots. Kept separate to prevent inlining bloat.
- **Deep equality on configure**: `mapEquals`/`listEquals` prevent version bump if the actual values haven't changed.

### Freeze / Unfreeze
- `freezeInheritance()` bakes effective parent values into child config fields (only nulls, unless `force: true`). Returns count of fields written.
- `unfreezeInheritance({Set<String>? fields, bool includeSelf})` restores dynamic inheritance by resetting frozen fields back to `null`.
- `_frozenFields: Set<String>` tracks which fields were bake-filled (not user-set). Explicit `configure()` calls promote fields out of frozen status automatically.

### Bulk Configuration
```dart
Logger.configureMultiple(Map<String, LoggerConfig> configurations)
```
- Validates ALL inputs atomically before writing any state (all-or-nothing)
- Uses `LoggerCache.invalidateMultiple` for O(U) single-pass cache eviction instead of O(N×M)

---

## NativeEngine Routing

After B-IR is generated, routing is chosen:

| Condition | Path |
|---|---|
| Sink is `NativeIsolateSink` + streaming mode | Offload: raw buffer sent to background isolate |
| Sink uses `AnsiEncoder` / `AutoConsoleEncoder` | Local: `BinaryAnsiEncoder` renders on main thread |
| Custom sinks or non-ANSI encoders | Fallback: `StandardEngine` object-based pipeline |

**Critical:** The presence of *any* decorator disables streaming mode. Even a no-op decorator forces Object Mode.

**Debugging tip:** If a NativeEngine fix has no effect, the engine has silently fallen to StandardEngine. Check for the `InternalLogger` fallback warning (fires once).

---

## Concurrency & Safety Rules

### No Self-Logging in Core
`Arena`, sinks, and resource managers must use `print` (not `InternalLogger`). Re-entrant logging during active pipeline state clobbers native buffers and produces "No native data" errors.

### Try-Finally is Mandatory
Every engine `execute` call wraps in `try-finally`. The `finally` block MUST call `document.releaseRecursive(factory)`. This is the only safe path for returning both object pool nodes and native FFI buffers.

### Arena Concurrency (v0.8.7+)
- Waiter queue is now FIFO (was single-slot). No more racing waiters under async saturation.
- `receivePort` in Arena is lazy — safely closed and reconstructed on `clear()` / `disposeNative()`.

---

## Platform Compatibility

### Web
- Entry point `lib/logd.dart` is entirely platform-agnostic. Zero conditional imports at top level.
- Native features (`Arena`, `FileSink`, `IsolateSink`, `NativeEngine`) use co-located stubs: `*_native.dart` / `*_stub.dart`.
- Stubs throw descriptive `UnsupportedError` with cross-platform alternatives (`ConsoleSink`, `HttpSink`, `StandardEngine`).

### Stack Trace Parsing
- Supports VM, Chrome/V8, Firefox, Safari formats.
- Runtime detection via `const bool.fromEnvironment`.
- Frame filtering uses resolved `filePath` prefix matching (not raw string), preventing false-positives in monorepos where package name appears in directory paths.

---

## Key Modules

| Module | Location | Purpose |
|---|---|---|
| `LogDocument` / `LogNode` | `src/handler/document/` | Semantic IR tree |
| `TerminalLayout` | `src/handler/layout/` | Physical layout engine |
| `Arena` | `src/handler/engine/` | LIFO object pool + native buffer management |
| `NativeEngine` | `src/handler/engine/` | Binary IR generation and routing |
| `LoggerCache` | `src/logger/` | Versioned fast/slow path config resolution |
| `LoggerSerializationRegistry` | `src/logger/` | Cross-isolate serialization of all pipeline components |
| `LoggerMetrics` | `src/logger/` | Observability: cache hits/misses, handler failures, buffer leaks |
| `package:logd/testing.dart` | `lib/testing.dart` | `CaptureSink`, `TestLogger`, `hasLog` matcher |

---

## Performance Reference (v0.8.3 Benchmarks)

| Benchmark | Before | After | Delta |
|---|---|---|---|
| `FullPipeline` latency | 4.67 µs | 3.05 µs | −34.7% |
| `ArenaFullPipeline` latency | 6.61 µs | 4.36 µs | −34.0% |
| `NativeEngineOffload` latency | 103.32 µs | 68.59 µs | −33.6% |
| `FramingSqueeze` throughput | 1,876 ops/s | 2,692 ops/s | +43.5% |
| GC pressure (Raw Machine) | 191.20 KB/10k | **0.00 KB/10k** | Eliminated |
| GC pressure (Framing Squeeze) | 196.00 KB/10k | **0.00 KB/10k** | Eliminated |

Any change to `TerminalLayout` or bitmask logic requires a benchmark verification run (>5% regression = block).
