# logd Core — Session Log
> Append-only. Each entry records what was attempted, what broke, what was learned.
> Never edit past entries. Add new entries at the top.

---

## 2026-08-19 | v0.9.4 | Hot-Path Origin Bypass & Ambient Structured Context (MDC)

### What We Did
- **Origin Bypass (`includeOrigin: false`)**: Bypassed `StackTrace.current` VM unwinding and regex parsing when caller origin is not needed and `stackMethodCount == 0`, delivering ~5x throughput speedup (~2.38 µs/log). Preserved explicit stack traces and frame count collections.
- **Ambient Structured Context (`LogContext.run` / MDC)**: Implemented Zone-based ambient context propagation across synchronous execution and async `await` chains without threading maps through method parameters.
- **Scope Hierarchy & Fast Path**: Scopes merge hierarchically (inner overrides outer for scope duration). `LogContext.merge()` performs 0 heap allocations when no context is active.
- **Formatter Integration**: Formatter suite (`StructuredFormatter`, `PlainFormatter`, `JsonFormatter`, `ToonFormatter`) and `ContextFilter` seamlessly render and filter `LogEntry.context`.
- **Validation & Benchmarks**: Added `lazy_stack_benchmark.dart`, `log_context_benchmark.dart`, `origin_bypass_demo.dart`, `ambient_context_demo.dart`, and full test suites with 100% pass rate across 2,513 tests.
- **Documentation**: Updated `README.md`, `CHANGELOG.md`, `doc/logger/architecture.md`, `doc/logger/README.md`, and `doc/stack_trace/architecture.md`.

### Key Decisions
- `context` is treated as core payload data (like `message`, `error`, `stackTrace`), rather than suppressible envelope metadata in `LogMetadata` (`timestamp`, `logger`, `origin`). This maintains backward compatibility and prevents silent data drops.

---

## 2026-08-05 | v0.9.3 | Target Handlers & Dual-Mode `.async()` Offloading

### What We Did
- **Pre-Wired `{Target}Handler` Architecture (ADR-006)**: Replaced multi-stage manual pipeline wiring with 8 strongly-typed convenience subclasses: `ConsoleHandler`, `HtmlFileHandler`, `JsonFileHandler`, `PlainFileHandler`, `ToonFileHandler`, `MarkdownFileHandler`, `HttpDashboardHandler`, `MemoryHandler`.
- **Dual-Mode `.async()` Factory Constructors**: Added `.async()` constructors across all 6 output-bound handlers, automatically offloading formatting, decoration, and physical I/O to background worker isolates (~15 µs return).
- **Safety by Design**: Kept `MemoryHandler` (in-process heap) and `HttpDashboardHandler` (local socket server) strictly synchronous in-process to avoid cross-isolate state disconnects.
- **Modular Entry Point**: Created `package:logd/advanced.dart` exposing low-level engine and isolate internals (`AsyncHandler`, `ArenaEngine`, `NativeEngine`, `IsolateSink`, `LogEngine`) for engine authors, simplifying the primary `package:logd/logd.dart` export surface.

---

## 2026-08-01 | v0.9.2 | Theme Isolate State Preservation & SQLite Satellite Package

### What We Did
- **Theme Brightness Transport**: Fixed theme brightness state loss across multi-isolate boundaries in `LoggerSerializationRegistry`. Preserved `LogBrightness` state (`dark` vs `light`) across `AsyncHandler` and `IsolateSink` transfers.
- **High-Contrast Light Theme**: Added WCAG AA-compliant high-contrast amber/red/green color palette mappings to `LogColorScheme.lightScheme` and `DefaultHtmlStylesheet`.
- **Deep Hierarchy Safeguards**: Verified 12-level deep logger tree configuration resolution completes in < 50 µs/lookup; enforced `Logger.maxHierarchyDepth` safety limit warnings.
- **Ecosystem Expansion**: Launched [`logd_sqlite`](https://pub.dev/packages/logd_sqlite) satellite package (v0.1.0) for high-performance SQLite WAL log persistence.

---

## 2026-07-28 | v0.9.1 | Native TOON Format & Protocol Auto-Detect Encoders

### What We Did
- **Tree-Oriented Object Notation (TOON)**: Implemented native `ToonFormatter` for semantic IR and `ToonEncoder` for string/ANSI rendering; integrated with live HTTP dashboard viewer; authored `doc/toon_spec.md`.
- **Protocol Auto-Detect Encoders (`AutoEncoder`)**: Standardized `'logd.encoder'` metadata contract, enabling default sinks (`ConsoleSink`, `FileSink`, `HttpSink`, `SocketSink`) to auto-delegate to matching physical encoders.
- **Self-Declaring Wrapping Strategies**: Added `requiredStrategy` getter to `LogEncoder`, allowing `EncodingSink` to default to the encoder's minimum required wrapping strategy.
- **In-Memory Ring Buffer (`MemorySink`)**: Added bounded `MemorySink<T>` and capacity capping (`maxEntries`) on `LogBuffer`.
- **Stack Trace Symbol Hooks**: Added `@experimental` `SymbolResolver` hook to `StackTraceParser` for custom symbol demangling and deobfuscation.
- **ADRs 002–005**: Authored architecture decision records covering cache invalidation, sparse storage, unmodifiable collections, and internal logger contracts.

---

## 2026-07-22 | v0.9.0 | Core API Stabilization & Semver Contract (Phase 1)

### What We Did
- **API Stabilization**: Audited all public exports; decorated low-level FFI/native components with `@experimental`; froze `LogFormatter`, `LogDecorator`, `LogSink`, and `Handler` as stable extension points.
- **Semver Specification**: Published `doc/semver_contract.md` defining stability tiers and breaking change policies.
- **Unified Theme Architecture**: Consolidated semantic color palettes into `LogColorScheme` (5 levels) and visual styling into `LogStyle`; standardized `StyleDecorator` as the single source of truth for attaching theme metadata to `document.metadata['logd.theme']`.
- **Extracted `HtmlStylesheet`**: Decoupled CSS/JS generation from `HtmlEncoder` into interchangeable `HtmlStylesheet` interface.

---

## 2026-07-18 | v0.8.9 | Web Source Mapping & Polymorphic Serialization

### What We Did
- **Web Source Mapping (Phase B)**: Enabled translation of Chrome, Firefox, and Safari stack traces back to original Dart source coordinates and deobfuscated method names via `.js.map` source maps.
- **Polymorphic Serialization Fix**: Fixed a bug where custom log sinks or filters registered in multi-isolate environments failed to serialize due to generic type erasure.
- **Timezone Parameter Hardening**: Hardened named timezone parameter parsing with input validation.

---

## 2026-07-12 | v0.8.8 | Async Isolate Offloading & Live HttpServer Dashboard

### What We Did
- **Isolate Offloading (`AsyncHandler`)**: Overhauled background worker isolate offloading with reusable `IsolateWorker` lifecycle manager.
- **Embedded Dashboard (`HttpServerSink`)**: Added loopback HTTP dashboard server with WebSocket upgrade for real-time live log telemetry.
- **Lifecycle Guarantees**: Added public `Future<void> dispose()` contract to `Handler` base class and `ready` startup completers.

---

## 2026-07-08 | v0.8.7 | Core Stabilization & Concurrency Hardening

### What We Did
- Replaced single-slot Arena waiter with a FIFO queue → eliminates race conditions under high async saturation
- Enforced Arena pool caps: 512 objects, 1000 buffers
- Made `receivePort` in Arena lazy (closed + reconstructed on `clear()` / `disposeNative()`)
- `NativeIsolateSink`: added crash detection + 2s auto-respawn
- Capped startup pre-ready buffer at 200 packets (prevents OOM on slow worker startup)
- Added optional timeout to all `Handler` instances
- Made `configureMultiple` fully atomic (validate all → write all or nothing)
- Added rate-limited warnings on repeated handler failures
- Added `SocketSink` exponential backoff (max 5 min)
- `NetworkSink`: List → Queue for O(1) removals
- Lazy `StackTrace.current`: skip evaluation if explicit trace is supplied
- Scoped cache invalidation for pattern-match updates (only affected loggers)
- Multi-isolate stress test: 10,000 concurrent logs across 5 isolates, zero deadlocks

### Bugs Hit
- None noted at engine level (this was a hardening release)

### Key Decisions
- Pool cap values (512 / 1000) chosen to prevent memory spikes under heavy continuous workloads without over-constraining the common case

---

## v0.8.6 | Sub-Library Restructuring & Web Fix

### What We Did
- Fixed critical Web compilation crash: `dart:ffi` / `dart:io` were leaking into the entry point
- Dissolved monolithic `native_handler.dart` into 8 clean sub-libraries
- Pushed platform conditional exports to leaf level (each feature owns its own stub)
- `PrintSink._staticWrite` promoted to `@internal` public to allow `ConsoleSink` cross-library reference
- Fixed stack trace parser monorepo false-positives (frame first, then path prefix check)

### Root Cause
- The monolithic `46-part` part tree made it impossible to express clean web/native compile boundaries

---

## v0.8.5 | Bulk Configuration API

### What We Did
- `Logger.configureMultiple(Map<String, LoggerConfig>)` — atomic bulk configuration
- `LoggerCache.invalidateMultiple` — O(U) single-pass eviction instead of O(N×M)
- Refactored single-logger `configure` to delegate to `configureMultiple`
- Exposed `LoggerConfig` publicly (removed `@internal`)

---

## v0.8.4 | Core Maturation, Testing Utilities, Flutter Decoupling

### What We Did
- `LoggerConfig` made fully `@immutable` + `copyWith`
- `LoggerSerializationRegistry` for cross-isolate transport of all pipeline components
- `Logger.exportConfig()` / `Logger.importConfig()` for isolate transfer
- `stackMethodCount` resolution: key-by-key map merge up hierarchy (not full replace)
- Graceful fallback logging via `Logger.fallbackHandler` when all handlers throw
- `LoggerMetrics`: cacheHits, cacheMisses, cacheInvalidations, handlerFailures, bufferAllocations, bufferLeaks, drops
- `LogBuffer` LIFO pool (32 max) + `Finalizer` leak detection
- `package:logd/testing.dart`: `CaptureSink`, `TestLogger`, `hasLog` matcher
- Web + V8/Firefox/Safari stack trace parsing
- Minute-granularity timezone offset caching; `Timestamp.dateOnly` with static formatter cache
- Flutter moved from runtime to dev dependencies → pure Dart support

### Key Decision
- `autoSinkBuffer` on `LogBuffer` defaults to `false` (data lost on leak). Enforces explicit lifecycle control. Intentional.

---

## v0.8.3 | Performance Optimization Pass

### What We Did
- Allocation-free `hierarchyDepth`: char code scan instead of `split('.').length`
- Lazy timestamp token formatting: eager map of 30+ entries → on-demand `_resolveToken`
- Fast/slow path split in `LoggerCache._resolve` → JIT-inlineable fast path
- In-place cache invalidation with `removeWhere` (no intermediate key list)
- Allocation-free parent name resolution: `lastIndexOf('.')` + `substring`

### Performance Gains
- FullPipeline: −34.7% latency | ArenaFullPipeline: −34.0% | NativeEngineOffload: −33.6%
- GC pressure eliminated to 0.00 KB/10k on raw and framing paths

---

## v0.8.2 | Inheritance System Maturation

### What We Did
- `_frozenFields: Set<String>` tracking on `LoggerConfig`
- `unfreezeInheritance({Set<String>? fields, bool includeSelf})` — selective, scoped unfreeze
- `freezeInheritance({bool force})` — re-snapshot support, returns field count written
- `exportHierarchy()` — includes `implicit` flag and resolved `effective` values
- `formatHierarchy()` / `printHierarchy({sink})` — pure string visual tree
- Ghost node detection + warnings on implicit freeze
- `Logger.reset([name])` — public, supports both global and scoped subtree reset

### Key Decision
- Shipped in v0.8.2 (patch) instead of v0.9.0 because all changes were purely additive. No breaking changes.
