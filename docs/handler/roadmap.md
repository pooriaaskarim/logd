# Handler Roadmap

## Completed

### ✅ P0: BoxFormatter Refactoring
**Goal**: Separate visual framing from content formatting.
**Result**: Successfully split into `StructuredFormatter` and `BoxDecorator`.
- [x] Create `BoxDecorator` class implementing `LogDecorator`
- [x] Extract layout logic from `BoxFormatter` into `StructuredFormatter`
- [x] Deprecate `BoxFormatter`, provide migration guide
- [x] Add tests for decorator + formatter composition

### ✅ P0: Decorator Composition Research
**Goal**: Define rules for multi-decorator interaction.
**Result**: Established a flexible pipeline model.
- [x] Document current decorator execution order (Manual pipeline)
- [x] Create test matrix for common decorator combinations
- [x] Define decorator contract regarding line structure assumptions
- [x] Propose conflict resolution strategy (Independent coloring + Idempotency tags)
- [x] Fixed `BoxDecorator` to be robust against multi-line input and long lines
- [x] Implemented `HierarchyDepthPrefixDecorator` for visual nesting
- [x] Implemented Independent Border Coloring in `BoxDecorator`

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
