# Handler Roadmap

## Active Development

### 🔴 P0: BoxFormatter Refactoring
**Goal**: Separate visual framing from content formatting.

**Current State**: `BoxFormatter` couples content layout with ASCII border rendering.

**Proposed Split**:
1. **BoxDecorator**: Adds ASCII borders around pre-formatted lines
2. **StructuredFormatter** (proposed name): Formats log entry fields in the current BoxFormatter's layout style without borders

**Implementation**:
- [ ] Create `BoxDecorator` class implementing `LogDecorator`
- [ ] Extract layout logic from `BoxFormatter` into `StructuredFormatter`
- [ ] Deprecate `BoxFormatter`, provide migration guide
- [ ] Add tests for decorator + formatter composition

**Alternative Names**: `LayoutFormatter`, `DetailFormatter`, `VerboseFormatter`

---

### 🔴 P0: Decorator Composition Research
**Context**: Multiple decorators may conflict or depend on ordering.

**Research Questions**:
1. **Interaction**: How do decorators affect each other's output?
   - Example: `AnsiColorDecorator` + `BoxDecorator` - does color apply inside or outside boxes?
   - Example: Two decorators both adding prefixes - what's the final order?

2. **Conflict Detection**: When do decorators produce invalid output?
   - Example: `TruncateDecorator(40)` + `BoxDecorator` - truncation breaks box width
   - Proposal: Add `DecoratorValidator` interface?

3. **Ordering Requirements**: Should decorator order be explicit or automatic?
   - Option A: User-specified order (current implementation)
   - Option B: Decorators declare dependencies/priorities
   - Option C: Handler validates and reorders decorators

**Action Items**:
- [ ] Document current decorator execution order (index 0 = first applied)
- [ ] Create test matrix for common decorator combinations
- [ ] Define decorator contract regarding line structure assumptions
- [ ] Propose conflict resolution strategy
- [ ] Add `@experimental` decorators to test composition patterns

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
