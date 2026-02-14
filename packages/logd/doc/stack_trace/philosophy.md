# Stack Trace Design Philosophy

This document outlines the core design principles and rationale behind the stack_trace module implementation.

## 1. Caller Detection Priority

### Goal
Extract the user's code location rather than library internals.

### The Problem
Standard stack traces include frames from the logging library itself:

```
#0 Logger._log (package:logd/logger.dart:123)
#1 Logger.info (package:logd/logger.dart:456)
#2 MyService.processRequest (package:myapp/service.dart:78)
```

The relevant frame is #2, not #0 or #1. Users want to know where *their* code called the logger, not where the logger's internal implementation is.

### Implementation Strategy
The parser iterates frames sequentially, skipping those matching configured package filters (e.g., `package:logd/`) until finding user code.

**Rationale**:
- **Simplicity** - Linear scan is easy to understand and debug
- **Flexibility** - Package-based filtering covers most use cases
- **Extensibility** - Custom filter callback allows arbitrary logic

**Trade-off**: O(n) scan vs. more complex heuristics. Acceptable because:
- Most stack traces are shallow (< 20 frames)
- Early exit on first match minimizes cost
- Regex compilation is the real bottleneck, not iteration

---

## 2. Defensive Parsing

### Principle
Parsing failures must not break logging.

### Rationale
Stack trace format may vary across:
- **Dart VM versions** - Format could change in future releases
- **Platform differences** - VM vs Web vs AOT have different formats
- **Obfuscation** - Release builds mangle names
- **Runtime environments** - Flutter vs pure Dart

### Behavior
If regex matching fails or produces malformed data, `parse()` returns a `StackFrameSet` with a null caller rather than throwing exceptions. The logging pipeline continues with degraded information rather than crashing.

**Example**:
```dart
final info = parser.parse(stackTrace: StackTrace.fromString('malformed'));
// info.caller: null (no exception thrown)
```

**Philosophy**: Logging is a diagnostic tool. It should never cause the application to fail. Better to have incomplete logs than no application.

---

## 3. Regex-Based Parsing vs. AST Parsing

### Decision
Use regex pattern matching instead of AST-based parsing.

### Rationale

**Why Regex**:
- **Simplicity** - Single pattern covers 95% of cases
- **Performance** - Regex is fast for simple patterns
- **No Dependencies** - No need for external parsing libraries
- **Dart VM Format is Stable** - Format hasn't changed significantly in years

**Why Not AST**:
- **Overkill** - Stack traces are simple, structured strings
- **Complexity** - AST parsing requires tokenization, grammar, etc.
- **Performance** - AST parsing is slower for simple cases
- **Maintenance** - More code to maintain and test

**Trade-off**: Regex is fragile to format changes, but the format is stable and the defensive parsing strategy mitigates risk.

---

## 4. No Caching of Parsed Results

### Decision
Do not cache `CallbackInfo` objects.

### Rationale

**Why No Caching**:
- **Uniqueness** - Each log call has a unique stack trace
- **Memory Cost** - Caching would accumulate unbounded entries
- **Lookup Cost** - Hash computation for stack trace strings is expensive
- **Hit Rate** - Near-zero cache hit rate in practice

**Exception**: The logger module *could* benefit from caching parsed frames when extracting both caller and stack frames from the same trace. This is a **cross-module optimization opportunity** (see roadmap).

**Philosophy**: Don't optimize prematurely. Measure first, then optimize hot paths.

---

## 5. Immutability

### Principle
All data structures are immutable.

### Rationale

**Benefits**:
- **Thread Safety** - Can be safely shared across isolates
- **Predictability** - No hidden state mutations
- **Testability** - Easier to reason about in tests

**Implementation**:
- `CallbackInfo` - All fields `final`, marked `@immutable`
- `StackTraceParser` - `const` constructor, all fields `final`

**Trade-off**: Slightly more memory allocations vs. safety and simplicity. Acceptable because:
- `CallbackInfo` objects are small (5 fields)
- Created once per log call, not in tight loops
- Immutability enables compiler optimizations

---

## 6. Package Filtering Strategy

### Decision
Use prefix matching on `package:<name>/` format.

### Rationale

**Why Prefix Matching**:
- **Simplicity** - Easy to understand and configure
- **Dart Convention** - Matches Dart's package URI format
- **Performance** - String contains check is O(n) but fast in practice

**Alternative Considered**: Regex patterns for filtering
- **Rejected** - Too complex for users to configure
- **Rejected** - Performance overhead of regex compilation

**Extensibility**: `customFilter` callback allows users to implement arbitrary filtering logic when package-based filtering isn't sufficient.

---

## 7. Leading Underscore Removal

### Decision
Strip leading underscores from private class names.

### Rationale

**Problem**: Dart private classes are prefixed with `_`:
```dart
class _MyPrivateClass {
  void method() {}
}
```

Stack trace shows: `_MyPrivateClass.method`

**Solution**: Remove leading underscore for cleaner output:
```dart
className: className.replaceFirst(RegExp('^_'), ''),
```

**Philosophy**: Logs are for humans. Private implementation details are noise. Show the semantic name, not the language-level encoding.

**Trade-off**: Loses information about privacy. Acceptable because:
- Privacy is a compile-time concept, not runtime
- Users can still see the full method in `fullMethod` field if needed

---

## 8. Early Exit Optimization

### Principle
Stop processing as soon as the first valid frame is found.

### Rationale

**Performance**: Most stack traces have irrelevant frames at the top (logger internals). Scanning the entire trace would waste CPU.

**Implementation**:
```dart
while (index < lines.length) {
  // ... filtering logic ...
  final info = _parseFrame(frame);
  if (info == null) continue;

  caller ??= info;
  if (maxFrames == 0 || frames.length >= maxFrames) {
    break;  // Early exit
  }
}
```

**Trade-off**: The `parse()` method now collects both caller and frames in a single pass, making early exit even more effective — it stops as soon as the required number of frames are collected.

---

## 9. Column Information Ignored

### Decision
Parse but discard column numbers from stack frames.

### Rationale

**Current Regex**: `#\d+\s+(.+)\s+\((.+):(\d+)(?::\d+)?\)`
- Group 4 (column) is optional and not captured

**Why Ignore**:
- **Limited Value** - Line number is sufficient for most debugging
- **Inconsistent** - Not all platforms provide column information
- **Simplicity** - Reduces `CallbackInfo` field count

**Future**: Could be added if users request it (see roadmap).

---

## Summary of Design Principles

1. **Caller Detection Priority** - Extract user code, not library internals
2. **Defensive Parsing** - Never crash, degrade gracefully
3. **Regex-Based Parsing** - Simple, fast, sufficient for stable format
4. **No Caching** - Unique traces make caching ineffective
5. **Immutability** - Thread-safe, predictable, testable
6. **Package Filtering** - Simple prefix matching with extensibility
7. **Leading Underscore Removal** - Human-readable output
8. **Early Exit** - Optimize for common case (shallow traces)
9. **Column Information Ignored** - Simplicity over completeness
