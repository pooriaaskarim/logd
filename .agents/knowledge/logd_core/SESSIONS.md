# logd Core — Session Log
> Append-only. Each entry records what was attempted, what broke, what was learned.
> Never edit past entries. Add new entries at the top.

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
