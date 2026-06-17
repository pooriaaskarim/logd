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

### ~~🟡 P1: Fix `_extractStackFrames` Using Wrong Parser~~ ✅ v0.6.3

**Resolved**: `_extractStackFrames()` was removed entirely. `Logger._log()` now uses `parse()` which performs single-pass parsing with the configured `stackTraceParser`.

**TODO**:
- [x] Replace `const StackTraceParser()` with configured parser
- [x] Refactored to single-pass via `parse()` — `_extractStackFrames()` deleted

---

### ~~🟡 P1: Validate `configure()` Inputs~~ ✅ v0.6.3

**Resolved**: Input validation added to `Logger.configure()`.

**TODO**:
- [x] Reject negative `stackMethodCount` values (`ArgumentError`)
- [x] Reject empty handlers list (`ArgumentError`)
- [x] Tests added for all invalid-input paths
- [ ] Validate `stackMethodCount` keys are valid `LogLevel` values (deferred — enum constraint makes this low-risk)

---

### ~~🟡 P1: Fix Freeze No-Op Version Bump~~ ✅ v0.6.3

**Resolved**: `freezeInheritance()` now tracks `bool changed` per config and only bumps `_version` + calls `invalidate()` when at least one field was actually populated.

**TODO**:
- [x] Add `changed` tracking to `freezeInheritance()`
- [x] Skip version bump when nothing changed
- [x] Tests added for both no-op and effective freeze cases

---

### ~~🟡 P1: Decide on Null-Message Behavior~~ ✅ v0.6.3

**Decision**: Keep current behavior — `null` produces an empty string. Documented in `_log()` doc comment.

**Rationale**: Changing to skip would be a behavioral breaking change; `"null"` string would be misleading for code that intentionally passes null.

**TODO**:
- [x] Decision: keep empty string
- [x] Document in `_log()` API docs
- [x] Test added

---

### ~~🟡 P1: Prevent LogBuffer Leaks~~ ✅ v0.6.4 (Ongoing)

**Resolved**: Added a `Finalizer` to `LogBuffer` that detects when a buffer is garbage collected without being sinked. 
- Logged as `LogLevel.warning` via `InternalLogger`.
- `autoSinkBuffer` now defaults to **`false`** (data is lost by default, enforcing explicit lifecycle management).
- Support for `error` and `stackTrace` added to `LogBuffer`.

**TODO**:
- [x] **Documentation**: Documented `autoSinkBuffer` behavior and importance of `.sink()`
- [x] **Finalizer-based tracking**: Implemented via `Finalizer` with stack trace capturing for leaks
- [x] **New Default**: `autoSinkBuffer` now defaults to `false`
- [ ] **Max-size safeguard**: Add optional `maxEntries` limit on `LogBuffer` to bound memory growth in the "forgot to sink" case (Deferred)
- [-] **Add lint rule** to warn about acquiring a buffer without sinking it (Working on it: branch [mororepo+linter](https://github.com/pooriaaskarim/logd/tree/feat/monorepo%2Blinter)) 
- [x] Tests added for leak detection state and error/stackTrace fields

---

## Phase 2 — Inheritance System Maturation

Depends on Phase 1 (particularly the freeze no-op fix).

### ~~🟡 P1: Inheritance Maturation (Monitoring, Unfreeze & Visibility)~~ ✅ v0.8.2

**Issue**: Once frozen, inheritance can never be restored. Additionally, the inheritance system lacks visibility for advanced users.

**Challenge**: Distinguishing "user explicitly set X" from "X was copied during freeze."

**Solution**: Track frozen fields with `Set<String> _frozenFields` per config.

**TODO**:
- [x] Add monitoring utilities to track the state of the inheritance system
- [x] Add `_frozenFields` tracking to `LoggerConfig`
- [x] `freezeInheritance()` populates `_frozenFields` for each field it fills
- [x] `unfreezeInheritance()` nulls out only `_frozenFields` entries, restoring dynamic resolution
- [x] Test: freeze → unfreeze → parent change → child updates dynamically again
- [x] Architecture & Philosophy Refinement: Further document the nuances of hierarchical overrides vs. freezing

---

### 🟢 P2: Review `@immutable` Annotations

**Issue**: Most `@immutable` annotations were added in v0.3.1, but `LoggerConfig` and `_ResolvedConfig` may need review.

**TODO**:
- [x] Audit remaining classes for immutability gaps
- [ ] Consider making `LoggerConfig` immutable (assess breaking-change impact)

---

## Phase 3 — Performance & Cache Efficiency

### 🟡 P1: Optimize Descendant Invalidation (O(n) → O(m))

**Issue**: Cache invalidation scans entire cache on every `configure()`.

**Location**: `LoggerCache.invalidate()` in [`logger.dart`](../../packages/logd/lib/src/logger/logger.dart)

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

### ~~🟢 P2: Eliminate Redundant Stack Trace Parsing~~ ✅ v0.6.3

**Resolved**: `StackFrameSet` data class and `parse()` method added to `StackTraceParser`. `Logger._log()` now calls `parse()` once for both caller and frame extraction. `_extractStackFrames()` removed entirely.

**Cross-Reference**: See [stack_trace roadmap](../stack_trace/roadmap.md).

**TODO**:
- [x] Implement `StackFrameSet` in stack_trace module
- [x] Implement `parse()` in `StackTraceParser`
- [x] Update `Logger._log()` to use single-pass API
- [x] `_extractStackFrames()` removed
- [ ] Benchmark improvement (deferred)

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

**Issue**: Hard to understand current logger tree structure at runtime.

**TODO**:
- [x] Implement `Logger.printHierarchy()` debug utility
- [x] Implement `Logger.exportHierarchy()` → `Map<String, dynamic>`
- [x] Show: name, explicit config, effective (resolved) config, frozen fields
- [x] Document in README

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

### ~~🔵 P3: Production Reset API~~ ✅ v0.8.2

**Issue**: `clearRegistry()` is `@visibleForTesting`, no public reset.

**Use Case**: Long-lived servers, plugin systems, multi-tenant apps.

**TODO**:
- [x] Expose `Logger.reset()` or `Logger.clearAll()`
- [x] Add warning documentation (loses all configs)
- [ ] Consider partial reset: `Logger.reset('subtree')`

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

| Item | Logger Side | Stack Trace Side | Status |
|------|-------------|------------------|--------|
| Redundant parsing | `_log()` uses `parse()` | `StackFrameSet` + `parse()` | ✅ v0.6.3 |
| Regex caching | — | `static final _frameRegex` | ✅ v0.6.3 |
| Wrong parser in `_extractStackFrames` | Resolved: `_extractStackFrames()` removed | — | ✅ v0.6.3 |

See [stack_trace roadmap](../stack_trace/roadmap.md) for the stack_trace module's priorities.

---

## Test Coverage Gaps

### Deep Hierarchy Performance Test
- 10+ level hierarchy, measure resolution latency
- Set budget: < 1ms for 10 levels

### ~~Partial Freeze Test~~ ✅ v0.6.3
Covered by `freezeInheritance no-op optimization` test group.

### ~~Stack Frame Parser Test~~ ✅ v0.6.3
Resolved by switch to `parse()` — configured parser is always used.

---

## Completed ✅

| Item | Version | Summary |
|------|---------|---------|
| Deep equality for collections | v0.6.1 | `mapEquals`/`listEquals` prevent redundant cache invalidation |
| Dynamic hierarchy depth | v0.6.1 | `LogEntry.hierarchyDepth` computed from name, not stored |
| API protection with `@internal` | v0.6.1 | `LogEntry` constructor and `InternalLogger` marked internal |
| `@immutable` annotations | v0.3.1 | Applied to all core configuration and handler classes |
| Freeze concurrent-mutation fix | v0.6.2 | `freezeInheritance()` snapshots keys with `.toList()` |
| Fix `_extractStackFrames` parser | v0.6.3 | Uses configured `stackTraceParser`; method removed in favor of `parse()` |
| Validate `configure()` inputs | v0.6.3 | Rejects negative `stackMethodCount` and empty `handlers` list |
| Fix freeze no-op version bump | v0.6.3 | Tracks `changed` flag, skips invalidation when no fields populated |
| Null-message behavior | v0.6.3 | Decision: `null` → empty string, documented in `_log()` |
| Regex caching (stack_trace) | v0.6.3 | Regex compiled once as `static final _frameRegex` |
| Redundant parsing elimination | v0.6.3 | `StackFrameSet` + `parse()` — single-pass parsing |
| LogBuffer leak protection | v0.6.4 | Finalizer-based detection and atomic error/stackTrace support |

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
