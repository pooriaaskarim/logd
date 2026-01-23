# Handler Roadmap

## Completed

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
- [x] Add `MarkdownFormatter` and `HTMLFormatter`

### ✅ P0: LLM-Optimized Logging (TOON)
**Goal**: Create a format that is "native" to AI agents.
**Result**: Introduced `ToonFormatter`.
- [x] Implement Token-Oriented Object Notation (TOON) spec
- [x] Efficient header-first streaming logic
- [x] Optional semantic tagging for colorized TOON output

### ✅ P1: Shared LogField System
**Goal**: Unify data access across all formatters.
**Result**: Created `LogField` enum and extension.
- [x] Decouple field extraction from JSON/TOON formatters
- [x] Allow dynamic field selection in any supported formatter

### ✅ ✅ P0: Visual Showcase (Logd Theatre)
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

### ✅ P1: ANSI Leakage in PainFormatter
- [*]
---

## Active Development

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
- [ ] `HttpSink`: POST logs to REST endpoint with batching
- [ ] `SqliteSink`: Persist logs to local database with schema
- [ ] `SentrySink`: Direct integration with error tracking
- [ ] `MemorySink`: In-memory buffer for testing/debugging

---

### 🟡 P1: Gradual Field Customization
**Context**: Following the success of `LogField` in JSON and TOON, users want similar control in other formatters.

**Proposal**:
- [ ] Implement `LogField` support in `StructuredFormatter`
- [ ] Implement `LogField` support in `PlainFormatter`
- [ ] Create a shared `FieldFormatter` mixin to reduce duplication

---

### 🟡 P1: Structured Context Support
**Context**: Modern apps need to log semi-structured data (maps, objects) per log entry.

**Proposal**:
- [ ] Add `Map<String, dynamic> context` to `LogEntry` / `Logger` methods
- [ ] Update `JsonFormatter` and `ToonFormatter` to incorporate arbitrary context keys
- [ ] Allow filtering based on context values (e.g., `ContextFilter('userId', '123')`)

---

### 🟢 P2: Web-Based Log Viewer (Logd Dashboard)
**Context**: Terminal output is great, but remote debugging needs more.

**Proposal**:
- [ ] Implement `HttpServerSink` that serves a small Vite/React dashboard
- [ ] Real-time log streaming via WebSockets
- [ ] Browser-side filtering and search across all attached handlers


### 🟡 P1: HTML Logging Consolidation & Simplification
**Context**: We currently have both `HtmlFormatter` and `HtmlSink`. With the planned `HttpServerSink` (Dashboard), we need to evaluate if both are necessary or if they can be unified.

**Research Tasks**:
- [ ] Evaluate if `HtmlFormatter` should be simplified to only emit structured semantic tags (like `JSON`).
- [ ] Determine if `HtmlSink` CSS should be moved to a shared theme system.
- [ ] Consider if a single `WebLogHandler` could manage both static file generation and future server-side streaming.

---

## Fixes

---
