# Handler Roadmap

## Completed

### ✅ v0.8.3: Performance, Structured Context & Parity
**Goal**: Optimize performance bottlenecks, support structured logging context, and achieve full cross-platform compatibility on Windows.
**Result**: Fully stabilized cache and formatting hot-paths, full structured context propagation across formatters, and resolved all timezone and layout constraints on Windows.
* **Performance Optimizations**:
  - [x] Optimize `LoggerCache._resolve` with inline-friendly fast-paths
  - [x] Optimize `TimestampFormatter` token formatting by ordering by token frequency
  - [x] Make hierarchy depth calculation allocation-free by counting dots
  - [x] Introduce $O(m)$ descendant invalidation reverse-index in `LoggerCache`
* **Structured Context Support**:
  - [x] Add `Map<String, dynamic> context` to `LogEntry` / `Logger` methods
  - [x] Integrate structured context maps into all core formatters (Json, Toon, Plain)
  - [x] Add context merging and sinking to `LogBuffer`
* **Cross-Platform Parity**:
  - [x] Fix Windows path separator issues in rotation tests
  - [x] Fix golden test CRLF line-ending mismatches on Windows
  - [x] Resolve Windows timezone names to standard IANA timezone identifiers via Unicode CLDR mapping table

---

### ✅ v0.8.1: FFI Layout Parity & Stabilization
**Goal**: Achieve 100% visual layout parity between the NativeEngine and StandardEngine rendering paths.
**Result**: Verified across 2,048 differential test configurations. `BinaryAnsiEncoder` now produces character-for-character identical output to the standard ANSI path.
- [x] Implement state-aware word-wrap simulator in `BinaryAnsiEncoder`
- [x] Add `_DecoratedState` for nested decorator leading-width tracking
- [x] Harden FFI pointer bounds checking for memory safety
- [x] Introduce `three_engines_comparison.dart` benchmark on a level playing field
- [x] Archive M15 milestone record in `packages/benchmarks/records/`
- [x] Restore `StandardEngine` as the universal default engine
- [x] Fix iOS `ProcessException` on timezone fetch (closes #21)
- [x] Merge into `dev`
- [x] PR to `master` and cut `v0.8.1` / `v0.8.3` release tags

---

### ✅ v0.8.0: The Engine & Schema Milestone
**Goal**: Consolidate high-performance native rendering with AI-native structured schemas.
**Result**: Fully stabilized Standard, Arena, and Native execution engines with support for B-IR v2 serialization and TOON explicit schemas.
* **TOON Schema Maturity**:
  - [x] Define semantic `ToonType` system (iso8601, enum, markdown, etc.)
  - [x] Implement aligned, multi-line schema headers
  - [x] Add Enum introspection for log levels in schema
  - [x] Update `TerminalLayout` to detect and render explicit schemas in console
* **Engine Optimizations (Binary IR & Native Engine)**:
  - [x] Define B-IR v1 & v2 instruction stream specifications
  - [x] Implement `BinaryIRWriter` for linearized document streaming
  - [x] Create `NativeEngine` with fast-path bypassing object-tree traversal
  - [x] Standardize 16-byte B-IR header with color/padding support
  - [x] Implement `BinaryAnsiEncoder` as reference native-compatible renderer
  - [x] Achieve ~13x throughput improvement over standard heap engine
  - [x] Build golden-testing suite for complete engine parity verification
  - [x] Stabilize LIFO-based Arena memory allocation and deterministic resource release

### ✅ P0: BoxFormatter Refactoring
**Goal**: Separate visual framing from content formatting.
**Result**: Successfully split into `StructuredFormatter` and `BoxDecorator`.
- [x] Create `BoxDecorator` class implementing `LogDecorator`
- [x] Extract layout logic from `BoxFormatter` into `StructuredFormatter`
- [x] Deprecate `BoxFormatter`, provide migration guide
- [x] Add tests for decorator + formatter composition

### ✅ P0: Semantic Segment Refactoring
**Goal**: Enable granular control over log content.
**Result**: Introduced `LogLine` and `LogSegment` architecture.
- [x] Implement `LogSegment` with `Set<LogTag>` support
- [x] Update all formatters to emit `LogLine`
- [x] Implement fine-grained tagging in `StructuredFormatter`
- [x] Add `JsonPrettyFormatter` with semantic styling and customizable fields
- [x] Add MarkdownEncoder and HtmlEncoder

### ✅ P1: Shared LogField System
**Goal**: Unify data access across all formatters.
**Result**: Created `LogField` enum and extension.
- [x] Decouple field extraction from JSON/TOON formatters
- [x] Allow dynamic field selection in any supported formatter

### ✅ P0: Visual Showcase (Logd Theatre)
**Goal**: Demonstrate complex capabilities in a single interactive dashboard.
**Result**: Created `example/log_theatre.dart`.
- [x] Implement mock dashboard UI in terminal
- [x] Showcase real-time multi-handler processing
- [x] Demonstrate all border styles and coloring configurations

### ✅ P0: Centralized Layout Management
**Goal**: Consolidate layout constraints and remove redundant parameters.
**Result**: Moved `lineLength` to `Handler` and added `preferredWidth` to `LogSink`.
- [x] Remove `lineLength` from `StructuredFormatter` and `BoxDecorator`
- [x] Implement `LogSink.preferredWidth` across all sink types
- [x] Update `LogContext` to provide `availableWidth`
- [x] Migrate all examples and tests to the new model

### ✅ P0: Unified Layout Pipeline (v0.6.1)
**Goal**: Eliminate scattered output and redundant wrapping logic.
**Result**: Centralized all wrapping into the `Handler` pipeline.
- [x] Implement implicit wrapping in `Handler.log`
- [x] Add `totalWidth` and `contentLimit` to `LogContext`
- [x] Port `SuffixDecorator` to the new layout model
- [x] Fix ANSI fragment sanitation and "phantom line" bugs

### ✅ P1: Responsive Metadata Alignment
- [x] Add `alignToEnd` support to `SuffixDecorator`
- [x] Ensure suffixes respect structural (box) boundaries

### ✅ P1: Recursive JSON Inspection
- [x] Implement recursive detection in `JsonPrettyFormatter`
- [x] Add tab-to-space normalization for environmental stability

### ✅ P1: Network Sinks (HttpSink & SocketSink)
**Context**: Users require reliable network logging for centralized log aggregation and real-time monitoring.

**Result**: Implemented specialized network sinks extending `NetworkSink` base class.
- [x] `HttpSink`: POST logs to REST endpoint with batching and exponential backoff retries
- [x] `SocketSink`: Real-time WebSocket streaming with auto-reconnection
- [x] `DropPolicy` for memory-safe buffer management (`discardOldest`, `discardNewest`)
- [x] Dependency injection support for testability (`client` and `channel` parameters)
- [x] Comprehensive test coverage (8 tests passing)

### ✅ P1: Semantic Encoder Inversion (v0.6.5)
**Goal**: Decouple formatting intent from physical serialization.
**Result**: Formatter produces semantic IR (`MapNode`/`ListNode`), while `LogEncoder` handles serialization.
- [x] Implement `JsonEncoder` and `ToonEncoder`
- [x] Refactor `EncodingSink` to be protocol-agnostic
- [x] Update `ToonFormatter` and `JsonFormatter` to emit semantic documents
- [x] Fix session-aware headers via `LogEncoder.preamble(document)`

---

## Active Development

### 🟡 v0.8.4: Maintenance, Technical Debt & Context Filtering (Active)
**Goal**: Resolve pure-Dart compatibility packaging issues, investigate SuffixDecorator performance overhead, introduce TOON fallback warnings, and implement structured context filters.
- [ ] Move `flutter` SDK dependency from `dependencies` to `dev_dependencies` in `pubspec.yaml` (closes pure-Dart resolution issues)
- [ ] Profile `SuffixDecorator` to identify the cause of its high rendering latency (~1,942 µs)
- [ ] Implement debug-mode warnings in `NativeEngine` when fallback to `StandardEngine` formatting is triggered (e.g. on TOON formats)
- [ ] Implement `ContextFilter` to enable filtering logs by keys/values in the structured context Map

---

## Features

### 🟡 P1: Async Formatter Support
**Context**: Heavy serialization (complex JSON) blocks the calling isolate.

**Proposal**:
- [ ] Add `AsyncFormatter` interface with `Future<Iterable<String>> format(LogEntry)`
- [ ] Create `AsyncHandler` wrapper that offloads formatting to a worker isolate
- [ ] Benchmark performance improvement on large objects

---

### 🟡 P1: Additional Sinks
**Context**: Users require diverse output destinations.

**Planned Sinks**:
- [ ] `SqliteSink`: Persist logs to local database with schema
- [ ] `SentrySink`: Direct integration with error tracking
- [ ] `MemorySink`: In-memory buffer for testing/debugging

---

### 🟡 P1: Context Filtering Support
**Context**: Once structured context is present, users should be able to filter logs based on context keys or values.

**Proposal**:
- [ ] Implement `ContextFilter` to filter log entries based on matching key-value pairs (e.g. `ContextFilter('userId', '123')`)

---

### 🟢 P2: Web-Based Log Viewer (Logd Dashboard)
**Context**: Terminal output is great, but remote debugging needs more.

**Proposal**:
- [ ] Implement `HttpServerSink` that serves a small Vite/React dashboard
- [ ] Real-time log streaming via WebSockets
- [ ] Browser-side filtering and search across all attached handlers

---

### 🟡 P1: HTML Logging Consolidation & Simplification
**Context**: We currently have both `HtmlFormatter` and `HtmlSink`. With the planned `HttpServerSink` (Dashboard), we need to evaluate if both are necessary or if they can be unified.

**Research Tasks**:
- [ ] Evaluate if `HtmlFormatter` should be simplified to only emit structured semantic tags (like `JSON`).
- [ ] Determine if `HtmlSink` CSS should be moved to a shared theme system.
- [ ] Consider if a single `WebLogHandler` could manage both static file generation and future server-side streaming.
