# Logger Module Roadmap

This document tracks planned improvements, known issues, and TODO items for the logger module, organized by priority and phased for dependency-aware implementation.

---

## Priority System

- 🔴 **P0 (Critical)**: Blocks maturity, must fix before v1.0
- 🟡 **P1 (High)**: Important for production use, correctness issues
- 🟢 **P2 (Medium)**: Nice-to-have, quality-of-life improvements
- 🔵 **P3 (Low)**: Future considerations, micro-optimizations

---

## Phase 1 — Correctness & Safety

Items in this phase are prerequisites for subsequent phases.

### 🟡 P1: Validate `configure()` Inputs

**Issue**: No validation of configuration values, allowing invalid states.

**Problems**:
- `stackMethodCount` could have negative values
- `handlers` could be empty list (no output)
- No validation that `stackMethodCount` keys are valid `LogLevel` values

**TODO**:
- [ ] Reject negative `stackMethodCount` values (throw `ArgumentError`)
- [ ] Reject empty handlers list (throw `ArgumentError`)
- [ ] Validate `stackMethodCount` keys are valid `LogLevel` values
- [ ] Add tests for every invalid-input path

---

### 🟡 P1: Fix Freeze/Iterate Race Condition

**Issue**: `freezeInheritance()` mutates configs while iterating the registry.

**Fix**: Collect target keys first, then apply changes in a separate pass:

```dart
void freezeInheritance() {
  final targets = _registry.keys
      .where((k) => k == name || _isDescendant(k, name))
      .toList();              // snapshot keys

  for (final key in targets) {
    final config = _registry[key]!;
    bool changed = false;
    if (config.enabled == null) { config.enabled = enabled; changed = true; }
    if (config.logLevel == null) { config.logLevel = logLevel; changed = true; }
    // ... remaining fields ...
    if (changed) {
      config._version++;
      LoggerCache.invalidate(key);
    }
  }
}
```

**TODO**:
- [ ] Implement two-phase approach (collect → mutate)
- [ ] Skip version bump when nothing changed (addresses no-op freeze invalidation too)
- [ ] Add concurrency stress test

> [!NOTE]
> This single fix resolves three former roadmap items: the race condition, the no-op freeze invalidation, and the unnecessary version bumps.

---

### 🟡 P1: Prevent LogBuffer Leaks

**Issue**: If a user acquires a buffer but never calls `sink()`, memory is leaked and content is lost.

**Context**: LogBuffers are designed for accumulating log entries across the execution path of an algorithm or multi-step operation, then sinking atomically at the end. This means a callback-based `autoSink()` wrapper would not fit the use case — the writes happen across method boundaries, not within a single scope.

**TODO**:
- [ ] **Documentation**: Prominently document the `try/finally` pattern in README + API docs
- [ ] **Debug-mode tracking**: In debug builds, track acquired-but-not-sinked buffers (e.g., via `InternalLogger` warning when the same logger acquires a new buffer while a previous one was never sinked)
- [ ] **Max-size safeguard**: Add optional `maxEntries` limit on `LogBuffer` to bound memory growth in the "forgot to sink" case
- [ ] **Add lint rule** to warn about acquiring a buffer without sinking it
- [ ] Add tests for leak detection and max-size behavior

---

### 🟡 P1: Decide on Null-Message Behavior

**Issue**: `logger.info(null)` silently produces an empty string. Users may expect `"null"` or a skip.

**Current Behavior**: `message?.toString() ?? ''` (empty string)

**TODO**:
- [ ] Choose: empty string / `"null"` / skip entirely
- [ ] Document the choice in API docs
- [ ] Add tests

---

## Phase 2 — Inheritance System Maturation

Depends on Phase 1 (particularly the freeze race condition fix).

### 🟡 P1: Add `unfreezeInheritance()`

**Issue**: Once frozen, inheritance can never be restored.

**Use Case**: Testing, plugin reload, configuration hot-reload.

**Challenge**: Distinguishing "user explicitly set X" from "X was copied during freeze."

**Solution**: Track frozen fields with `Set<String> _frozenFields` per config.

**TODO**:
- [ ] Add `_frozenFields` tracking to `LoggerConfig`
- [ ] `freezeInheritance()` populates `_frozenFields` for each field it fills
- [ ] `unfreezeInheritance()` nulls out only `_frozenFields` entries, restoring dynamic resolution
- [ ] Test: freeze → unfreeze → parent change → child updates dynamically again
- [ ] Update architecture + philosophy docs

---

### 🟡 P1: Inheritance System Maturation

**Context**: The current inheritance system is powerful but lacks visibility and certain control mechanisms for advanced users.

**TODO**:
- [ ] Runtime Hierarchy Overview: Implement an API to visualize or traverse the current logger tree configuration at runtime
- [ ] Complete unfreeze support (see above)
- [ ] Architecture & Philosophy Refinement: Further document the nuances of hierarchical overrides vs. freezing

---

### 🟡 P1: Add `@immutable` to Appropriate Classes

**Issue**: `LoggerConfig` and `_ResolvedConfig` should be immutable or marked.

**TODO**:
- [ ] Review all classes for immutability
- [ ] Add `@immutable` where appropriate
- [ ] Consider making `LoggerConfig` immutable (assess breaking-change impact)

---

## Phase 3 — Performance & Cache Efficiency

### 🟡 P1: Optimize Descendant Invalidation (O(n) → O(m))

**Issue**: Cache invalidation scans entire cache on every `configure()`.

**Location**: `Logger.configure()` in [`logger.dart`](../../lib/src/logger/logger.dart)

**Current Complexity**: O(n × m) where n = cache size, m = key length

**Options**:

| Approach | Lookup | Trade-off |
|----------|--------|-----------|
| Reverse index `Map<String, Set<String>>` | O(1) | Memory overhead |
| Prefix trie | O(m) where m = name length | Implementation complexity |

**Recommendation**: Start with reverse index (simpler, sufficient for realistic hierarchy sizes).

**TODO**:
- [ ] Implement `_descendants` reverse index, populated on `Logger.get()`
- [ ] Update `invalidate()` to use reverse index
- [ ] Benchmark before/after on hierarchy of 100+ loggers
- [ ] Add regression test for invalidation correctness

---

### 🟢 P2: Eliminate Redundant Stack Trace Parsing

**Issue**: Stack trace is parsed twice — once for caller, once for frames.

**Location**: `Logger._log()`

**Cross-Reference**: See [stack_trace roadmap](../stack_trace/roadmap.md) for coordinated solution.

**TODO**:
- [ ] Implement `ParsedStackTrace` in stack_trace module
- [ ] Update `Logger._log()` to call `parseComplete()` once
- [ ] Benchmark improvement
- [ ] Update both modules' docs

---

### 🔵 P3: String Concatenation in Origin Building

**Issue**: Multiple string concatenations in `_buildOrigin()`.

**TODO**:
- [ ] Profile to confirm this is measurable
- [ ] Refactor to `StringBuffer` for complex origin strings
- [ ] Add fast path for the common simple case

---

### 🔵 P3: LogBuffer Memory Pooling

**Issue**: Each buffer access creates a new `LogBuffer` instance.

**TODO**:
- [ ] Implement object pool with configurable max size
- [ ] Benchmark allocation reduction
- [ ] Document pool behavior and sizing guidance

---

## Phase 4 — Developer Experience

### 🟢 P2: Configuration Import/Export

**Issue**: No way to share logger config across isolates.

**Use Case**: Server with worker isolates, multi-isolate app coordination.

**TODO**:
- [ ] Design serialization format (JSON?)
- [ ] Implement `Logger.exportConfig()` → `Map<String, dynamic>`
- [ ] Implement `Logger.importConfig(Map<String, dynamic>)`
- [ ] Handle non-serializable fields (Timestamp, StackTraceParser, Handlers)
  - Option A: Skip them
  - Option B: Allow registration of serializers
- [ ] Add tests
- [ ] Document isolate coordination pattern

---

### 🟢 P2: `stackMethodCount` Merge Semantics

**Issue**: Partial `stackMethodCount` maps don't merge with defaults/parent.

**Current**: All-or-nothing replacement.

**TODO**:
- [ ] **Decision**: Keep current behavior OR implement merge
- [ ] If merge: update resolution, documentation, and add tests
- [ ] If keep current: document clearly in `Logger.configure` docs and add FAQ entry

**Recommendation**: Document current behavior first, consider merge if requested.

---

### 🟢 P2: Metrics & Observability

**Issue**: No way to monitor logger health or performance.

**TODO**:
- [ ] Design `LoggerMetrics` API (cache hit/miss, drops, handler failures, buffer usage)
- [ ] Opt-in only (zero overhead when disabled)
- [ ] Implement `LoggerMetrics.toJson()` for export
- [ ] Document in README

---

### 🟢 P2: Bulk Configuration API

**Issue**: Configuring multiple loggers requires multiple calls.

**TODO**:
- [ ] Design bulk configuration API
- [ ] **Option A**: `Logger.configureMultiple(Map<String, LoggerConfig>)`
- [ ] **Option B**: `Logger.configurePattern(pattern: 'app.*', ...)`
- [ ] Ensure cache invalidation is batched (single pass, not N passes)
- [ ] Add tests and documentation

---

### 🟢 P2: Test Utilities

**Issue**: Hard to test code that uses loggers.

**TODO**:
- [ ] Create `TestLogger` utility class
- [ ] Implement `CaptureSink` for log capture
- [ ] Add assertion helpers (`hasLog`, `hasLogMatching`, etc.)
- [ ] Add `package:logd/testing.dart` export
- [ ] Document testing patterns with examples

---

### 🟢 P2: Logger Hierarchy Visualization

**Issue**: Hard to understand current logger tree structure.

**TODO**:
- [ ] Implement `Logger.printHierarchy()` debug utility
- [ ] Implement `Logger.exportHierarchy()` → `Map<String, dynamic>`
- [ ] Show: name, explicit config, effective (resolved) config, frozen fields
- [ ] Document in README

---

### 🟢 P2: Graceful Handler Degradation

**Issue**: If all handlers fail, logs are silently lost (except InternalLogger output).

**TODO**:
- [ ] Implement fallback-to-console when all configured handlers fail
- [ ] Make fallback behavior configurable
- [ ] Document in README

---

## Phase 5 — Code Quality & Hardening

### 🔵 P3: Extract Constants to Named Constants

**Issue**: Magic numbers/strings in code.

**Examples**:
- `'global'` hardcoded everywhere
- `1` (skipFrames in `_log`)

**TODO**:
- [ ] Create `const _globalLoggerName = 'global'`
- [ ] Create `const _logMethodSkipFrames = 1`
- [ ] Update all usages

---

### 🔵 P3: Add Null Safety Asserts

**Issue**: Some code paths assume non-null without explicit checks.

**TODO**:
- [ ] Audit for potential `null` dereferences
- [ ] Add `assert(config != null)` where appropriate
- [ ] Enable stricter linter rules

---

### 🔵 P3: Add Hierarchy Depth Warning

**Issue**: No protection against accidentally deep hierarchies.

**TODO**:
- [ ] Define threshold (e.g., 10 levels)
- [ ] Log InternalLogger warning on first access of deep logger
- [ ] Make threshold configurable
- [ ] Document in philosophy.md

---

### 🔵 P3: Production Reset API

**Issue**: `clearRegistry()` is `@visibleForTesting`, no public reset.

**Use Case**: Long-lived servers, plugin systems, multi-tenant apps.

**TODO**:
- [ ] Expose `Logger.reset()` or `Logger.clearAll()`
- [ ] Add warning documentation (loses all configs)
- [ ] Consider partial reset: `Logger.reset('subtree')`

---

### 🔵 P3: Inconsistent Null Handling

**Issue**: Unclear behavior when `null` message is logged.

**Current Behavior**: `message?.toString() ?? ''` (empty string)

**TODO**:
- [ ] Decide on standard behavior (empty string, "null", or skip)
- [ ] Document behavior clearly
- [ ] Add tests for null message handling

---

### 🔵 P3: Add Concurrency Test

**Issue**: No test for rapid concurrent configuration changes.

**TODO**:
- [ ] Test multiple isolates configuring independently
- [ ] Test rapid `configure()` calls (stress test cache invalidation)
- [ ] Verify no race conditions in cache

---

### 🔵 P3: Architecture Decision Records (ADRs)

**Issue**: Design decisions not formally documented.

**TODO**:
- [ ] Create `doc/decisions/` directory
- [ ] Write ADRs for key decisions:
  - [ ] ADR-001: Hierarchical inheritance model
  - [ ] ADR-002: Version-based cache invalidation
  - [ ] ADR-003: Sparse configuration storage
  - [ ] ADR-004: Unmodifiable resolved collections
  - [ ] ADR-005: InternalLogger for fail-safe
- [ ] Use [MADR](https://adr.github.io/madr/) format

---

## Cross-Module Coordination

| Item | Logger Side | Stack Trace Side |
|------|-------------|------------------|
| Redundant parsing | Update `_log()` to use `parseComplete()` | Implement `ParsedStackTrace` + `parseComplete()` |
| Regex caching | — | Move regex to `static final` field |

See [stack_trace roadmap](../stack_trace/roadmap.md) for the stack_trace module's priorities.

---

## Test Coverage Gaps

### Partial Freeze Test
```dart
test('freezeInheritance with partial child overrides', () {
  Logger.configure('global', logLevel: LogLevel.trace, enabled: false);
  Logger.configure('app.ui', enabled: true);
  
  Logger.get('app').freezeInheritance();
  
  expect(Logger.get('app.ui').enabled, isTrue);
  expect(Logger.get('app.ui').logLevel, LogLevel.trace);
  
  Logger.configure('global', logLevel: LogLevel.error);
  expect(Logger.get('app.ui').logLevel, LogLevel.trace); // still frozen
});
```

### Deep Hierarchy Performance Test
- 10+ level hierarchy, measure resolution latency
- Set budget: < 1ms for 10 levels

---

## Completed ✅

| Item | Version | Summary |
|------|---------|---------|
| Deep equality for collections | v0.6.1 | `mapEquals`/`listEquals` prevent redundant cache invalidation |
| Dynamic hierarchy depth | v0.6.1 | `LogEntry.hierarchyDepth` computed from name, not stored |
| API protection with `@internal` | v0.6.1 | `LogEntry` constructor and `InternalLogger` marked internal |

---

## Rejected ❌

_(No rejected items at this stage.)_

---

## How to Contribute

1. **Claim**: Comment on GitHub issue
2. **Branch**: `feat/logger-<item-name>`
3. **Test**: Add tests before implementation
4. **Document**: Update docs alongside code
5. **Update**: Check off item and move to Completed
