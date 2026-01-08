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

### 🔴 P0: Document Default `enabled` Behavior

**Issue**: In release builds (`dart.vm.product = true`), loggers are disabled by default. This is buried in code and surprises users.

**Location**: [`logger.dart:149-150`](../../lib/src/logger/logger.dart#L149-L150)

**TODO**:
- [ ] Add warning in `Logger` class documentation
- [ ] Add example in README showing how to enable in production
- [ ] Consider adding runtime warning on first disabled log in production

**Example to add**:
```dart
/// ## Default Behavior
/// 
/// In **debug builds**, loggers are **enabled** by default.
/// In **release builds** (`dart.vm.product`), loggers are **disabled** by default.
/// 
/// To enable logging in production:
/// ```dart
/// Logger.configure('global', enabled: true);
/// ```
```

---

### 🟡 P1: Fix `sink()` vs `sync()` Documentation Mismatch

**Issue**: `LogBuffer` method is named `sink()`, but docs say `sync()`.

**Location**: 
- [`log_buffer.dart:21`](../../lib/src/logger/log_buffer.dart#L21) (implementation: `sink()`)
- [`logger.dart:393`](../../lib/src/logger/logger.dart#L393) (docs: `sync()`)

**TODO**:
- [ ] **Decision**: Rename `sink()` → `flush()` (clearer) OR fix docs to say `sink()`
- [ ] Update all documentation
- [ ] Add migration note if renaming

**Recommendation**: Rename to `flush()` - more standard term for this operation.

```dart
// Proposed
void flush() {
  if (isNotEmpty) {
    _logger._log(logLevel, toString(), null, StackTrace.current);
    clear();
  }
}
```

---

### 🟡 P1: Document Unmodifiable Collections

**Issue**: Getters return unmodifiable collections, but this isn't clear from API.

**Location**: [`logger.dart:342-351`](../../lib/src/logger/logger.dart#L342-L351)

**TODO**:
- [ ] Add `@pragma('vm:prefer-inline')` or similar hint
- [ ] Document in getter doc comments
- [ ] Add example of correct way to modify (via `configure()`)

**Example to add**:
```dart
/// List of handlers to process log entries.
/// 
/// **Note**: Returns an **unmodifiable list**. To change handlers:
/// ```dart
/// Logger.configure('name', handlers: [newHandler1, newHandler2]);
/// ```
/// 
/// Attempting to modify directly will throw:
/// ```dart
/// logger.handlers.add(h);  // ❌ UnsupportedError
/// ```
List<Handler> get handlers => LoggerCache.handlers(name);
```

---

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

_(Empty for now - track completed items here)_

---

## Rejected ❌

_(Track rejected ideas here with rationale)_

---

## How to Contribute

When working on TODOs:

1. **Claim**: Comment on GitHub issue or update this file with your name
2. **Branch**: Create feature branch `feat/logger-<todo-name>`
3. **Test**: Add tests before implementation
4. **Document**: Update docs alongside code
5. **Review**: Request review with link to this roadmap item
6. **Update**: Check off item and move to "Completed" section

---

## Version Milestones

### v0.x (Current)

- [x] Basic hierarchy and inheritance
- [x] Caching with version-based invalidation
- [x] Freezing mechanism
- [x] Deep equality for collections
- [ ] Complete P0 documentation items
- [ ] Complete P1 testing items

### v1.0 (Stable Release)

- [ ] All P0 items complete
- [ ] All P1 items complete
- [ ] 95%+ test coverage
- [ ] Comprehensive documentation
- [ ] Performance benchmarks established
- [ ] Migration guide for breaking changes (if any)

### v2.0 (Future)

- [ ] Consider breaking changes (immutable config, defaults, naming)
- [ ] Advanced features (import/export, merge semantics)
- [ ] Performance optimizations (trie-based cache)
