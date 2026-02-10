# Stack Trace Architecture

This document provides a technical overview of the stack_trace module implementation. It is intended for contributors and developers requiring a deeper understanding of the internal mechanics.

## File Structure

The stack_trace module is organized into 3 files:

| File | Lines | Purpose |
|------|-------|---------|
| [`stack_trace.dart`](../../lib/src/stack_trace/stack_trace.dart) | 7 | Part file aggregator |
| [`callback_info.dart`](../../lib/src/stack_trace/callback_info.dart) | 52 | Immutable data class for parsed frame information |
| [`stack_trace_parser.dart`](../../lib/src/stack_trace/stack_trace_parser.dart) | 102 | Core parsing engine with regex-based frame extraction |

## System Components

The stack_trace module consists of two primary components:
1. **The Parser**: Regex-based extraction engine
2. **The Data Model**: Immutable frame representation

### 1. StackTraceParser

**Location**: `StackTraceParser` class in [`stack_trace_parser.dart`](../../lib/src/stack_trace/stack_trace_parser.dart)

The parser is the core engine that converts raw stack trace strings into structured `CallbackInfo` objects.

**Configuration**:
- `ignorePackages` - List of package prefixes to skip (e.g., `['logd', 'flutter']`)
- `customFilter` - Optional callback for custom filtering logic

**Immutability**: The parser is marked `@immutable` and uses `const` constructor, making it safe to share across isolates.

### 2. CallbackInfo

**Location**: `CallbackInfo` class in [`callback_info.dart`](../../lib/src/stack_trace/callback_info.dart)

An immutable data class representing a single parsed stack frame.

**Fields**:
- `className` - Extracted class name (empty string for top-level functions)
- `methodName` - Method or function name
- `filePath` - File URI from the stack frame
- `lineNumber` - Line number as integer
- `fullMethod` - Complete method string (e.g., `'Class.method'`)

**Immutability**: Marked `@immutable` with all fields `final`, implements proper `==` and `hashCode`.

## Parsing Pipeline

When `extractCaller()` is called, the raw stack trace string is processed linearly:

```mermaid
flowchart TD
    Raw[Raw Stack String] --> Split[Split Lines]
    Split --> Loop[Iterate Frames]
    Loop --> Skip{Should Skip?}
    Skip -- Yes (Internal Pkg) --> Loop
    Skip -- No (User Code) --> Parse[Regex Parse]
    Parse --> Match{Matches?}
    Match -- Yes --> Struct[CallbackInfo]
    Match -- No --> Loop
    
    classDef inputStyle fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    classDef processStyle fill:#f5f5f5,stroke:#616161,stroke-width:2px,color:#000
    classDef outputStyle fill:#e8f5e9,stroke:#388e3c,stroke-width:2px,color:#000
    
    class Raw inputStyle
    class Split,Parse processStyle
    class Struct outputStyle
```

### Extraction Algorithm

**Location**: `StackTraceParser.extractCaller()` in [`stack_trace_parser.dart`](../../lib/src/stack_trace/stack_trace_parser.dart)

```dart
CallbackInfo? extractCaller({
  required StackTrace stackTrace,
  int skipFrames = 0,
}) {
  final lines = stackTrace.toString().split('\n');
  int index = skipFrames;

  while (index < lines.length) {
    final frame = lines[index].trim();
    
    // Skip empty frames
    if (frame.isEmpty) {
      index++;
      continue;
    }

    // Apply filtering
    if (_shouldIgnoreFrame(frame)) {
      index++;
      continue;
    }

    // Attempt to parse
    final info = parseFrame(frame);
    if (info != null) {
      return info;  // First valid frame wins
    }

    index++;
  }
  return null;  // No valid frame found
}
```

**Key Characteristics**:
1. **Linear scan** - Processes frames sequentially
2. **Early exit** - Returns immediately upon finding first valid frame
3. **Defensive** - Returns `null` instead of throwing on parse failure

### Frame Filtering

**Location**: `StackTraceParser._shouldIgnoreFrame()` in [`stack_trace_parser.dart`](../../lib/src/stack_trace/stack_trace_parser.dart)

Frames are skipped if:
1. **Custom filter rejects** - `customFilter` returns `false`
2. **Package match** - Frame contains `package:<pkg>/` where `<pkg>` is in `ignorePackages`

```dart
bool _shouldIgnoreFrame(String frame) {
  if (customFilter != null && !customFilter!(frame)) {
    return true;
  }
  return ignorePackages.any((pkg) => frame.contains('package:$pkg/'));
}
```

### Frame Parsing

**Location**: `StackTraceParser.parseFrame()` in [`stack_trace_parser.dart`](../../lib/src/stack_trace/stack_trace_parser.dart)

**Dart VM Stack Format**:
```
#<id>  <function> (<fileUri>:<line>:<column>)
```

**Example**:
```
#0 MyClass.myMethod (package:myapp/service.dart:42:7)
```

**Regex Pattern**:
```dart
final reg = RegExp(r'#\d+\s+(.+)\s+\((.+):(\d+)(?::\d+)?\)');
```

**Capture Groups**:
- Group 1: Function name (`MyClass.myMethod`)
- Group 2: File URI (`package:myapp/service.dart`)
- Group 3: Line number (`42`)
- Group 4: Column number (optional, currently ignored)

**Class/Method Extraction**:
```dart
final fullMethod = match.group(1)!;
final dotIndex = fullMethod.lastIndexOf('.');

final className = dotIndex != -1 
    ? fullMethod.substring(0, dotIndex) 
    : '';
    
final methodName = dotIndex != -1 
    ? fullMethod.substring(dotIndex + 1) 
    : fullMethod;
```

**Leading Underscore Removal**:
```dart
className: className.replaceFirst(RegExp('^_'), ''),
```
Private class names (e.g., `_MyClass`) have the leading underscore stripped for cleaner output.

## Performance Characteristics

### Time Complexity
- **extractCaller()**: O(n) where n = number of frames until first match
- **parseFrame()**: O(1) - Single regex match
- **Best case**: O(1) - First frame matches
- **Worst case**: O(n) - No frames match, scan entire trace

### Space Complexity
- **O(n)** for string splitting (creates array of lines)
- **O(1)** for regex matching (no additional allocations)

### Optimizations
1. **Early exit** - Stops at first valid frame, doesn't parse entire trace
2. **No caching** - Stack traces are unique per call, caching would waste memory
3. **Immutable results** - `CallbackInfo` can be safely shared without copying

## Edge Cases

### Empty Stack Traces
```dart
final caller = parser.extractCaller(stackTrace: StackTrace.fromString(''));
// Returns: null
```

### Malformed Frames
```dart
final info = parser.parseFrame('invalid frame format');
// Returns: null (regex doesn't match)
```

### All Frames Filtered
```dart
final parser = StackTraceParser(ignorePackages: ['myapp']);
final caller = parser.extractCaller(stackTrace: myAppStackTrace);
// Returns: null (all frames belong to 'myapp')
```

### Anonymous Functions
```dart
#0 <anonymous closure> (file.dart:10:5)
```
Parsed as:
- `className`: empty string
- `methodName`: `'<anonymous closure>'`

## Platform Differences

### Dart VM (Current Support)
Format: `#0 Class.method (package:app/file.dart:10:5)`
- ✅ Fully supported

### Dart Web (Not Yet Supported)
Formats vary by browser:
- Chrome: `at Function (http://localhost/main.dart.js:1234:56)`
- Firefox: `function@http://localhost/main.dart.js:1234:56`
- ❌ Not currently supported (see roadmap)

### Flutter AOT (Obfuscated)
Format: `#0 a.b (file.dart:10:5)`
- ⚠️ Parses successfully but names are mangled
- Requires symbol map for deobfuscation (see roadmap)

## Integration with Logger Module

The logger module uses `StackTraceParser` in two contexts:

### 1. Caller Extraction
**Location**: `Logger._log()` in logger module

```dart
final caller = stackTraceParser.extractCaller(
  stackTrace: stackTrace ?? StackTrace.current,
  skipFrames: 1,  // Skip Logger._log itself
);
```

### 2. Stack Frame Extraction
**Location**: `Logger._extractStackFrames()` in logger module

Currently uses separate parsing logic. **Optimization opportunity**: Combine with caller extraction to avoid redundant parsing (see roadmap).

## Equality and Hashing

Both `StackTraceParser` and `CallbackInfo` implement proper equality:

**StackTraceParser**:
```dart
bool operator ==(Object other) =>
    identical(this, other) ||
    other is StackTraceParser &&
    listEquals(ignorePackages, other.ignorePackages) &&
    customFilter == other.customFilter;
```

**CallbackInfo**:
```dart
bool operator ==(Object other) =>
    identical(this, other) ||
    other is CallbackInfo &&
    className == other.className &&
    methodName == other.methodName &&
    filePath == other.filePath &&
    lineNumber == other.lineNumber &&
    fullMethod == other.fullMethod;
```

This enables proper comparison in tests and cache keys.
