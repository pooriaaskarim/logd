# Edge Case Tests Validation Guide

## Overview

This directory contains rationalized edge case tests for the `handler` module. These tests validate robustness and ensure the system handles various scenarios gracefully, from Unicode characters to concurrent file I/O.

## Core Safety Tests

### 1. `null_safety_test.dart`
**Purpose**: Validates graceful handling of `null` fields, empty messages, and whitespace-only content.
**Key Scenarios**:
- `LogEntry` with `null` error or `stackTrace`.
- Very long logger names (triggers header wrapping).
- Empty or multiline whitespace messages.
- Single-character messages in boxed environments.

### 2. `decorator_safety_test.dart`
**Purpose**: Ensures decorators are robust and composable.
**Key Scenarios**:
- Deduplication of multiple instances of the same decorator type.
- Automatic sorting logic (Structural > Visual > Transform).
- `BoxDecorator` with extremely small line lengths.
- Lines containing only ANSI escape sequences.

### 3. `layout_safety_test.dart`
**Purpose**: Validates visual integrity across various encodings and string types.
**Key Scenarios**:
- Unicode (Chinese, etc.) and Emoji width calculations in boxes.
- ANSI escape code preservation across wrapped lines.
- Force-wrapping of extremely long words without spaces.
- Tolerance for malformed or non-standard ANSI sequences.

### 4. `filter_safety_test.dart`
**Purpose**: Ensures filtering logic is reliable and handles edge cases.
**Key Scenarios**:
- Logic for combining multiple filters (AND behavior).
- `RegexFilter` behavior with empty messages.
- Handling of complex regex patterns.

### 5. `sink_safety_test.dart`
**Purpose**: Validates I/O robustness, concurrency, and file rotation.
**Key Scenarios**:
- Rapid concurrent logging from multiple handlers to the same `FileSink`.
- Size-based rotation under extreme load.
- `TimeRotation` regression tests (ensures rotation triggers after intervals).

## Running Tests

### All Safety Tests
```bash
flutter test test/handler/edge_cases/
```

### Specific Test Area
```bash
flutter test test/handler/edge_cases/sink_safety_test.dart
```

## Troubleshooting
- **Unicode Widths**: If boxes are "scattered", verify `visibleLength` in `utils.dart`.
- **ANSI Preservation**: If colors "bleed" or stop at line breaks, check `wrapVisiblePreserveAnsi`.
- **Concurrent Failures**: If file logs are missing entries, ensure `FileSink` serialization logic (Mutex/Queue) is intact.
