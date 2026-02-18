# Stack Trace Module

The Stack Trace module provides utilities for parsing, filtering, and extracting structured information from Dart stack traces during logging events.

## Quick Start

```dart
import 'package:logd/logd.dart';

// Create a parser with package filtering
final parser = StackTraceParser(
  ignorePackages: ['logd', 'flutter'],
);

// Extract caller and stack frames in a single pass
final result = parser.parse(
  stackTrace: StackTrace.current,
  skipFrames: 1,  // Skip the parse call itself
  maxFrames: 3,   // Collect up to 3 frames
);

if (result.caller != null) {
  print('Called from: ${result.caller!.className}.${result.caller!.methodName}');
  print('Location: ${result.caller!.filePath}:${result.caller!.lineNumber}');
}

// Configure logger to use custom parser
Logger.configure('app',
  stackTraceParser: StackTraceParser(
    ignorePackages: ['logd', 'flutter', 'dart:async'],
  ),
);
```

## Component Overview

The stack_trace module consists of 4 source files:

### Core Components

#### [stack_trace_parser.dart](../../packages/logd/lib/src/stack_trace/stack_trace_parser.dart)
- **`StackTraceParser`** - Core parsing engine for extracting structured data from stack traces
- Configurable package filtering via `ignorePackages`
- Optional custom filtering via `customFilter` callback
- Regex-based frame parsing for Dart VM format

#### [stack_frame_set.dart](../../packages/logd/lib/src/stack_trace/stack_frame_set.dart)
- **`StackFrameSet`** - Immutable result of a single-pass parse
- Contains: caller (`CallbackInfo?`) and additional frames (`List<CallbackInfo>`)

#### [callback_info.dart](../../packages/logd/lib/src/stack_trace/callback_info.dart)
- **`CallbackInfo`** - Immutable data class representing a parsed stack frame
- Contains: class name, method name, file path, line number, full method string
- Provides equality and hash code implementations

#### [stack_trace.dart](../../packages/logd/lib/src/stack_trace/stack_trace.dart)
- Part file aggregator that combines the module components

## Capabilities

### 1. Single-Pass Parsing
Extract caller information and additional stack frames in one pass:

```dart
final result = parser.parse(
  stackTrace: StackTrace.current,
  skipFrames: 1,
  maxFrames: 5,  // 0 = caller only
);
// result.caller: CallbackInfo(className: 'MyClass', methodName: 'myMethod', ...)
// result.frames: up to 5 CallbackInfo entries
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
- `parse({required StackTrace stackTrace, int skipFrames = 0, int maxFrames = 0})` - Single-pass extraction of caller and stack frames, returns `StackFrameSet`

### StackFrameSet

**Fields**:
- `caller` - First relevant `CallbackInfo` (nullable)
- `frames` - List of additional `CallbackInfo` frames (may be empty)

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
