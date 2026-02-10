# Stack Trace Module Roadmap

This document tracks planned improvements, known issues, and TODO items for the stack_trace module, organized by priority.

---

## Priority System

- 🔴 **P0 (Critical)**: Blocks maturity, must fix before v1.0
- 🟡 **P1 (High)**: Important for production use, platform support
- 🟢 **P2 (Medium)**: Nice-to-have, quality-of-life improvements
- 🔵 **P3 (Low)**: Future considerations, edge cases

---

## 🔴 P0: Critical (Blocks v1.0)

*All critical issues have been resolved.*

---

## 🟡 P1: High Priority (Platform Support)

### Web Stack Trace Parsing
**Context**: Dart compiled to JavaScript produces different stack formats than VM.

**VM Format**: `#0 function (package:app/file.dart:10:5)`

**Web Formats**:
- Chrome: `at Function (http://localhost/main.dart.js:1234:56)`
- Firefox: `function@http://localhost/main.dart.js:1234:56`
- Safari: `function@http://localhost/main.dart.js:1234:56`

**TODO**:
- [ ] Add platform detection (check `dart.library.html` vs `dart.library.io`)
- [ ] Define regex patterns for each browser
- [ ] Map JS bundle locations back to Dart source (requires source maps in dev mode)
- [ ] Add browser-specific test suites
- [ ] Update documentation with web platform support

**Acceptance Criteria**:
- Parser works on Chrome, Firefox, Safari
- Tests pass on web platform
- Documentation updated

---

### Regex Compilation Caching
**Issue**: Regex is recompiled on every frame parse.

**Current Code**:
```dart
CallbackInfo? parseFrame(String frame) {
  final reg = RegExp(r'#\d+\s+(.+)\s+\((.+):(\d+)(?::\d+)?\)');
  final match = reg.firstMatch(frame);
  // ...
}
```

**TODO**:
- [ ] Move regex to static final field
- [ ] Benchmark performance improvement
- [ ] Update tests to verify behavior unchanged

**Proposed Solution**:
```dart
class StackTraceParser {
  static final _frameRegex = RegExp(r'#\d+\s+(.+)\s+\((.+):(\d+)(?::\d+)?\)');
  
  CallbackInfo? parseFrame(String frame) {
    final match = _frameRegex.firstMatch(frame);
    // ...
  }
}
```

**Acceptance Criteria**:
- Regex compiled once per class load
- Performance improvement measurable in benchmarks

---

## 🟢 P2: Medium Priority (Quality of Life)

### Async Boundary Detection
**Context**: Asynchronous stack traces include special frames:

```
#0 asyncFunction (file.dart:10)
<asynchronous suspension>
#1 caller (file.dart:5)
```

**Current Behavior**: Parser may skip the suspension frame incorrectly.

**TODO**:
- [ ] Detect `<asynchronous suspension>` markers
- [ ] Optionally include both synchronous caller and async origin
- [ ] Add `includeAsyncOrigin` configuration flag
- [ ] Document async frame semantics in architecture doc
- [ ] Add tests for async stack traces

**Acceptance Criteria**:
- Async suspension frames handled correctly
- Configuration option available
- Tests cover async scenarios

---

### Parsed Frame Caching
**Context**: Logger module parses same stack trace twice (caller + frames).

**Cross-Reference**: See [logger roadmap](../logger/roadmap.md) for coordinated solution

**Current State**:
- `extractCaller()` parses for origin
- `_extractStackFrames()` parses for stack frames
- Both parse the same `StackTrace` object

**TODO**:
- [ ] Design `ParsedStackTrace` data class
- [ ] Implement `parseComplete()` method
- [ ] Coordinate with logger module on API integration
- [ ] Benchmark performance improvement
- [ ] Update both modules' documentation

**Proposed API**:
```dart
class ParsedStackTrace {
  final CallbackInfo? caller;
  final List<String> frames;
}

ParsedStackTrace parseComplete({
  required StackTrace stackTrace,
  required int skipFrames,
  required int maxFrames,
});
```

**Acceptance Criteria**:
- Single parse pass for both caller and frames
- Logger module integrated with new API
- Performance improvement measurable

---

### Lazy Frame Parsing Optimization
**Current**: Parser processes frames until first match, already optimized.

**Further Optimization**:
- [ ] Benchmark parsing cost on deep stack traces (50+ frames)
- [ ] Consider extracting frame parsing to isolate for expensive operations
- [ ] Document performance characteristics in architecture doc

**Acceptance Criteria**:
- Benchmark results documented
- Performance budget established

---

## 🔵 P3: Low Priority (Future Enhancements)

### Symbol Deobfuscation
**Context**: Release builds with `--obfuscate` produce mangled names:

```
#0 a.b (file.dart:10)
```

**Blockers**: Requires access to symbol map generated during compilation.

**TODO**:
- [ ] Research feasibility of embedding symbol map in app
- [ ] Add `SymbolResolver` interface for external deobfuscation services
- [ ] Document manual deobfuscation workflow using `flutter symbolize`
- [ ] Add example of deobfuscation integration

**Acceptance Criteria**:
- API designed for symbol resolution
- Documentation includes deobfuscation guide

---

### Column Information Preservation
**Current**: Column numbers are parsed but discarded.

**Regex**: `#\d+\s+(.+)\s+\((.+):(\d+)(?::\d+)?\)`
- Group 4 (column) is optional and not captured

**TODO**:
- [ ] Add `columnNumber` field to `CallbackInfo`
- [ ] Update regex to capture column
- [ ] Handle platforms that don't provide column info
- [ ] Update tests and documentation

**Acceptance Criteria**:
- Column information available when provided
- Backward compatible with platforms without column info

---

### Batch Parsing API
**Issue**: No efficient way to parse multiple frames at once.

**TODO**:
- [ ] Design batch parsing API
- [ ] Implement `parseFrames(List<String> frames)`
- [ ] Optimize for bulk operations
- [ ] Add tests for batch parsing

**Proposed API**:
```dart
List<CallbackInfo?> parseFrames(List<String> frames) {
  return frames.map(parseFrame).toList();
}
```

**Acceptance Criteria**:
- Batch API available
- Performance comparable to individual parsing

---

## Cross-Module Optimizations

### Eliminate Redundant Stack Trace Parsing
**Modules**: stack_trace + logger

**Current State**:
- Logger calls `stackTraceParser.extractCaller()` for origin
- Logger calls `_extractStackFrames()` for stack frames
- Both parse the same `StackTrace` object

**Proposed Solution**: Implement `parseComplete()` method (see "Parsed Frame Caching" above)

**Coordination Required**:
- Stack trace module: Implement `parseComplete()` API
- Logger module: Update `Logger._log()` to use new API
- Both modules: Update documentation

**TODO**:
- [ ] Implement in stack_trace module first
- [ ] Coordinate with logger module integration
- [ ] Benchmark performance improvement
- [ ] Update both roadmaps when complete

---

## Known Limitations

### Format Dependency
**Issue**: Relies on `StackTrace.toString()` output format.

**Risk**: Breaking changes in Dart SDK require parser updates.

**Mitigation**: Defensive parsing returns `null` on failure rather than crashing.

**Future Work**: Monitor Dart SDK releases for format changes.

---

### Inline Functions
**Issue**: Anonymous closures appear as `<fn>` or `<anonymous closure>`, limiting usefulness.

**Current Behavior**: Parsed as method name, but not very informative.

**Future Work**: Consider enhancing with source location when available.

---

## Completed Items

### ✅ Basic Regex-Based Parsing
**Completed**: Initial release

Implemented regex-based parser for Dart VM stack format.

---

### ✅ Package Filtering
**Completed**: Initial release

Added `ignorePackages` configuration for filtering library internals.

---

### ✅ Custom Filtering
**Completed**: Initial release

Added `customFilter` callback for arbitrary filtering logic.

---

### ✅ Immutability
**Completed**: Initial release

All data structures marked `@immutable` for thread safety.
