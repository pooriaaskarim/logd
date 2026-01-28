# Logger Module Roadmap

This document tracks planned improvements, known issues, and TODO items for the logger module.

---

## Priority System

- 🔴 **P0 (Critical)**: Blocks maturity, must fix before v1.0
- 🟡 **P1 (High)**: Important for production use, DX issues
- 🟢 **P2 (Medium)**: Nice-to-have, quality-of-life improvements
- 🔵 **P3 (Low)**: Future considerations, rare edge cases

---

## Documentation & DX

### 🟢 P2: Add Architecture Decision Records (ADRs)

**Issue**: Design decisions (sparse storage, version-based invalidation, etc.) not formally documented.

**TODO**:
- [ ] Create `docs/decisions/` directory
- [ ] Write ADRs for key decisions:
  - [ ] ADR-001: Hierarchical inheritance model
  - [ ] ADR-002: Version-based cache invalidation
  - [ ] ADR-003: Sparse configuration storage
  - [ ] ADR-004: Unmodifiable resolved collections
  - [ ] ADR-005: InternalLogger for fail-safe

**Template**: Use [MADR](https://adr.github.io/madr/) format.

---

## Testing

### 🟡 P1: Add Test for Partial Freeze

**Issue**: Missing test coverage for freeze with partial child overrides.

**Location**: Test gap identified in analysis

**TODO**:
- [ ] Add test case:
  ```dart
  test('freezeInheritance with partial child overrides', () {
    Logger.configure('global', logLevel: LogLevel.trace, enabled: false);
    Logger.configure('app.ui', enabled: true); // Only enabled
    
    Logger.get('app').freezeInheritance();
    
    expect(Logger.get('app.ui').enabled, isTrue);      // Kept own
    expect(Logger.get('app.ui').logLevel, LogLevel.trace); // Froze from parent
    
    Logger.configure('global', logLevel: LogLevel.error);
    expect(Logger.get('app.ui').logLevel, LogLevel.trace); // Still frozen
  });
  ```

---

### 🟢 P2: Add Deep Hierarchy Performance Test

**Issue**: No test validating performance with deep hierarchies.

**TODO**:
- [ ] Create benchmark test with 10+ level hierarchy
- [ ] Measure resolution time
- [ ] Set performance budget (e.g., < 1ms for 10 levels)
- [ ] Add to CI

---

### 🟢 P2: Add Concurrency Test

**Issue**: No test for rapid concurrent configuration changes.

**TODO**:
- [ ] Test multiple isolates configuring independently
- [ ] Test rapid `configure()` calls (stress test cache invalidation)
- [ ] Verify no race conditions in cache

---

## Performance Optimizations

### 🟡 P1: Optimize Descendant Invalidation (O(n) → O(m))

**Issue**: Cache invalidation scans entire cache on every `configure()`.

**Location**: [`logger.dart:169-173`](../../lib/src/logger/logger.dart#L169-L173)

**Current Complexity**: O(n × m) where n = cache size, m = key length

**TODO**:
- [ ] **Option A**: Maintain reverse index `Map<String, Set<String>> _descendants`
  - Update on logger creation
  - O(1) lookup of descendants
  - Trade-off: Memory overhead
- [ ] **Option B**: Use prefix tree (trie) for cache storage
  - O(m) invalidation
  - More complex implementation
- [ ] Benchmark both approaches
- [ ] Implement chosen solution
- [ ] Add tests

**Recommendation**: Start with Option A (simpler, sufficient for most use cases).

```dart
// Proposed: Reverse index
class LoggerCache {
  static final Map<String, Set<String>> _descendants = {};
  
  static void _trackDescendant(String parent, String child) {
    _descendants.putIfAbsent(parent, () => {}).add(child);
  }
  
  static void invalidate(String loggerName) {
    _cache.remove(loggerName);
    final desc = _descendants[loggerName] ?? {};
    for (final d in desc) {
      _cache.remove(d);
    }
  }
}
```

---

### 🟢 P2: Skip No-Op Freeze Invalidations

**Issue**: `freezeInheritance()` always bumps version and invalidates, even if no fields changed.

**Location**: [`logger.dart:369-379`](../../lib/src/logger/logger.dart#L369-L379)

**TODO**:
- [ ] Track if any field was actually set
- [ ] Only bump version and invalidate if `changed == true`
- [ ] Add test verifying no-op freeze doesn't invalidate

```dart
// Proposed
void freezeInheritance() {
  for (final key in _registry.keys.toList()) {
    if (key == name || _isDescendant(key, name)) {
      final childConfig = _registry[key]!;
      bool changed = false;
      
      if (childConfig.enabled == null) {
        childConfig.enabled = enabled;
        changed = true;
      }
      // ... for all fields
      
      if (changed) {
        childConfig._version++;
        LoggerCache.invalidate(key);
      }
    }
  }
}
```

---

### 🔵 P3: Add Hierarchy Depth Warning

**Issue**: No protection against accidentally deep hierarchies.

**TODO**:
- [ ] Define threshold (e.g., 10 levels)
- [ ] Log InternalLogger warning on first access of deep logger
- [ ] Make threshold configurable
- [ ] Document in philosophy.md

---

## Feature Additions

### 🟡 P1: Inheritance System Maturation
**Context**: The current inheritance system is powerful but lacks visibility and certain control mechanisms for advanced users.

**TODO**:
- [ ] **Runtime Hierarchy Overview**: Implement an API to visualize or traverse the current logger tree configuration at runtime.
- [ ] **Unfreeze Support**: Implement `unfreezeInheritance()` to restore dynamic inheritance (see details in P1 item below).
- [ ] **Architecture & Philosophy Refinement**: Further document the nuances of hierarchical overrides vs. freezing.

---

### 🟡 P1: Add `unfreezeInheritance()`

**Issue**: Once frozen, can't restore dynamic inheritance.

**Use Case**: Testing, plugin reload, configuration hot-reload.

**TODO**:
- [ ] Design API: `logger.unfreezeInheritance()`
- [ ] Implementation: Set fields to `null` if they match parent's effective value
- [ ] Add tests for freeze → unfreeze → parent change → child updates
- [ ] Update documentation

**Challenge**: How to distinguish "explicitly set to value that happens to match parent" vs "frozen from parent"?

**Solution**: Add metadata `Map<String, Set<String>> _frozenFields` tracking which fields were frozen (not explicitly set).

---

### 🟢 P2: Add `stackMethodCount` Merge Semantics

**Issue**: Partial `stackMethodCount` maps don't merge with defaults/parent.

**Current**: All-or-nothing replacement.

**TODO**:
- [ ] **Decision**: Keep current behavior OR implement merge
- [ ] If merge:
  - [ ] Update resolution to merge with defaults
  - [ ] Update documentation
  - [ ] Add tests
- [ ] If keep current:
  - [ ] Document clearly in `Logger.configure` docs
  - [ ] Add FAQ entry

**Recommendation**: Document current behavior first, consider merge for v2.0 if requested.

---

### 🟢 P2: Add Configuration Import/Export

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

### 🔵 P3: Add Production Reset API

**Issue**: `clearRegistry()` is `@visibleForTesting`, no public reset.

**Use Case**: Long-lived servers, plugin systems, multi-tenant apps.

**TODO**:
- [ ] Expose `Logger.reset()` or `Logger.clearAll()`
- [ ] Add warning documentation (loses all configs)
- [ ] Consider partial reset: `Logger.reset('subtree')`

---

## Code Quality

### 🟡 P1: Add `@immutable` to Appropriate Classes

**Issue**: `LoggerConfig` and `_ResolvedConfig` should be immutable or marked.

**TODO**:
- [ ] Review all classes for immutability
- [ ] Add `@immutable` where appropriate
- [ ] Consider making `LoggerConfig` immutable (breaking change?)

---

### 🟢 P2: Extract Constants to Named Constants

**Issue**: Magic numbers/strings in code.

**Examples**:
- `'global'` hardcoded everywhere
- `1` (skipFrames in `_log`)

**TODO**:
- [ ] Create `const _globalLoggerName = 'global'`
- [ ] Create `const _logMethodSkipFrames = 1`
- [ ] Update all usages

---

### 🟢 P2: Add Null Safety Asserts

**Issue**: Some code paths assume non-null without explicit checks.

**TODO**:
- [ ] Audit for potential `null` dereferences
- [ ] Add `assert(config != null)` where appropriate
- [ ] Enable stricter linter rules

---

## Breaking Changes (Consider for v2.0)

### Make `LoggerConfig` Immutable

**Current**: Mutable fields, mutated in-place by `configure()`.

**Proposed**: Replace entire `LoggerConfig` instance on change.

**Benefit**: True immutability, easier reasoning.

**Cost**: More GC pressure, breaking change.

---

### Change Default `enabled` to `true` in Production

**Current**: Disabled in release builds.

**Proposed**: Always enabled by default.

**Benefit**: Less surprising.

**Cost**: Slight performance impact if not explicitly disabled.

---

### Rename `freezeInheritance()` → `lockConfiguration()`

**Current**: `freezeInheritance()` unclear to new users.

**Proposed**: `lockConfiguration()` / `unlockConfiguration()`.

**Benefit**: Clearer intent.

---

## Completed ✅

- **v0.6.1: Layout & Stability Refinement**
  - Implemented dynamic `hierarchyDepth` in `LogEntry` for guaranteed tree consistency.
  - Enforced internal security boundaries by marking `LogEntry` constructor and `Handler.log` as `@internal`.
  - Optimized `Logger.configure` with deep collection equality to prevent redundant cache clears.
  - Refined `InternalLogger` to ensure fail-safe error reporting during layout collapses.

---

## Rejected ❌

_(Track rejected ideas here with rationale)_

---

## How to Contribute

1. **Claim**: Comment on GitHub issue.
2. **Branch**: `feat/logger-<todo-name>`.
3. **Test**: Add tests before implementation.
4. **Document**: Update docs alongside code.
5. **Update**: Check off item and move to "Completed" section.

---

### v0.x (Current)
- [x] Hierarchical inheritance with version-based caching.
- [x] Zero-cost disabled logging and inheritance freezing.
- [x] Deep equality configuration optimization.
- [x] @internal protection for core data models.

### v1.0 (Stable)
- [ ] 95%+ test coverage and performance benchmarks.
- [ ] Comprehensive documentation (Logger + Handler integration).
- [ ] Refined ADRs for all major design decisions.

### v2.0 (Future)
- [ ] Trie-based cache for massive hierarchies.
- [ ] Cross-isolate configuration synchronization.

---

## Completed ✅

- **v0.6.1: Stability & Safety**
  - **Dynamic Depth**: `LogEntry.hierarchyDepth` is now computed from logger names.
  - **API Shielding**: Enforced `@internal` guards on `LogEntry` and `Handler.log`.
  - **Deep Equality**: Optimized `Logger.configure` to skip redundant invalidations.
  - **Fail-Safe**: Refined `InternalLogger` for robust terminal error reporting.

---

## Rejected ❌
*(No rejected items at this stage)*
