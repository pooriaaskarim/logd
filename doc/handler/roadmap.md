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
- [x] Add `JsonSemanticFormatter` for metadata-rich output
- [x] Add `MarkdownFormatter` and `HTMLFormatter`

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

### 🟢 P2: Batched Output
**Context**: Per-log I/O is inefficient for high-volume logging.

**Implementation**:
- [ ] Create `BufferedSink` decorator
- [ ] Configuration: buffer size (count) or time window (duration)
- [ ] Flush policy: on buffer full, on timer, or explicit flush()
- [ ] Thread-safety for concurrent log writes


## Fixes

---

## Known Issues

### ANSI Color Palette Limitation
**Current**: Only 16 basic colors supported.
**Impact**: Limited visual differentiation in terminals.
**Future**: Add 256-color and true-color support with capability detection.

### FileSink Rotation Timing
**Current**: Rotation check is synchronous but file operations are async.
**Impact**: Minor inconsistency in rotation boundary timing.
**Mitigation**: Document behavior; consider making check async in v2.0.
