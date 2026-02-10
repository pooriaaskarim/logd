# Stack Trace Module

The Stack Trace module provides utilities for parsing, filtering, and extracting structured information from Dart stack traces during logging events.

## Quick Start

```dart
import 'package:logd/logd.dart';

// Create a parser with package filtering
final parser = StackTraceParser(
  ignorePackages: ['logd', 'flutter'],
);

// Extract caller information
final caller = parser.extractCaller(
  stackTrace: StackTrace.current,
  skipFrames: 1,  // Skip the extractCaller call itself
);

if (caller != null) {
  print('Called from: ${caller.className}.${caller.methodName}');
  print('Location: ${caller.filePath}:${caller.lineNumber}');
}

// Configure logger to use custom parser
Logger.configure('app',
  stackTraceParser: StackTraceParser(
    ignorePackages: ['logd', 'flutter', 'dart:async'],
  ),
);
```

## Component Overview

The stack_trace module consists of 3 source files:

### Core Components

#### [stack_trace_parser.dart](../../lib/src/stack_trace/stack_trace_parser.dart)
- **`StackTraceParser`** - Core parsing engine for extracting structured data from stack traces
- Configurable package filtering via `ignorePackages`
- Optional custom filtering via `customFilter` callback
- Regex-based frame parsing for Dart VM format

#### [callback_info.dart](../../lib/src/stack_trace/callback_info.dart)
- **`CallbackInfo`** - Immutable data class representing a parsed stack frame
- Contains: class name, method name, file path, line number, full method string
- Provides equality and hash code implementations

#### [stack_trace.dart](../../lib/src/stack_trace/stack_trace.dart)
- Part file aggregator that combines the module components

## Capabilities

### 1. Caller Extraction
Identify the precise class, method, and line number where a log event originated:

```dart
final caller = parser.extractCaller(
  stackTrace: StackTrace.current,
  skipFrames: 1,
);
// Returns: CallbackInfo(className: 'MyClass', methodName: 'myMethod', ...)
```

### 2. Frame Filtering
Remove irrelevant frames from internal libraries:

```dart
final parser = StackTraceParser(
  ignorePackages: ['logd', 'flutter'],  // Skip these packages
);
```

Custom filtering logic:

```dart
final parser = StackTraceParser(
  customFilter: (frame) => !frame.contains('_internal'),
);
```

### 3. Frame Parsing
Parse individual stack frames into structured data:

```dart
final info = parser.parseFrame('#0 MyClass.method (package:app/file.dart:42:7)');
// Returns: CallbackInfo with parsed components
```

## API Reference

### StackTraceParser

**Constructor**:
```dart
const StackTraceParser({
  List<String> ignorePackages = const [],
  FrameFilter? customFilter,
});
```

**Methods**:
- `extractCaller({required StackTrace stackTrace, int skipFrames = 0})` - Extract first relevant caller
- `parseFrame(String frame)` - Parse a single frame string into CallbackInfo

### CallbackInfo

**Fields**:
- `className` - Class name (empty if top-level function)
- `methodName` - Method or function name
- `filePath` - File URI where call occurred
- `lineNumber` - Line number in file
- `fullMethod` - Complete method string (e.g., 'Class.method')

## Integration with Logger

The logger module uses `StackTraceParser` to extract caller information for log entries:

```dart
Logger.configure('app',
  stackTraceParser: StackTraceParser(
    ignorePackages: ['logd', 'flutter'],
  ),
);

final logger = Logger.get('app');
logger.info('Message');  // Automatically extracts caller using parser
```

## Documentation

- [Architecture](architecture.md) - Technical implementation details
- [Design Philosophy](philosophy.md) - Core principles and rationale
- [Roadmap](roadmap.md) - Planned improvements and known limitations
