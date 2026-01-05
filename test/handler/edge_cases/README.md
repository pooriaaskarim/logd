# Handler Edge Case Tests

This directory contains comprehensive tests for edge cases and robustness scenarios in the Handler module.

## Test Files

### `ansi_preservation_test.dart`
Tests for ANSI code preservation during wrapping and processing:
- Preserves ANSI codes when wrapping long colored text
- Preserves ANSI codes in box decorator with wrapping
- Handles multiple ANSI codes in sequence
- Handles empty strings with ANSI codes

### `empty_null_handling_test.dart`
Tests for handling empty, null, and edge case messages:
- Empty string messages
- Whitespace-only messages
- Very short messages
- Messages with only newlines
- Empty messages with decorators

### `unicode_handling_test.dart`
Tests for Unicode and special character handling:
- Unicode characters (Chinese, etc.)
- Emoji support
- Special ASCII characters
- Mixed Unicode and ASCII
- Long Unicode strings with wrapping

### `very_long_lines_test.dart`
Tests for handling very long lines and wrapping edge cases:
- Extremely long single lines
- Very long words without spaces
- ANSI code preservation in very long wrapped text
- Multi-line input with very long lines
- Box decorator with very long content

### `error_handling_test.dart`
Tests for error handling in the handler pipeline:
- Formatter exceptions
- Decorator exceptions
- Sink exceptions
- Filter exceptions
- Empty iterable handling

### `decorator_edge_cases_test.dart`
Tests for decorator edge cases and composition:
- Duplicate decorators (deduplication)
- Empty decorator list
- Decorator with empty input lines
- Box decorator idempotency
- ANSI decorator idempotency
- Decorator auto-sorting with mixed types

### `filter_edge_cases_test.dart`
Tests for filter edge cases:
- LevelFilter with all log levels
- RegexFilter with empty messages
- RegexFilter with special regex characters
- RegexFilter with invert option
- Multiple filters with edge cases
- Filters with very long messages
- Filters with Unicode characters

### `file_sink_concurrency_test.dart`
Tests for FileSink concurrency robustness:
- Rapid logging in loops (all entries should be written)
- Concurrent logging from multiple handlers
- Rapid logging with file rotation

## Running Tests

Run all edge case tests:
```bash
dart test test/handler/edge_cases/
```

Run a specific test file:
```bash
dart test test/handler/edge_cases/ansi_preservation_test.dart
```

## Coverage

These tests cover:
- ✅ ANSI code handling and preservation
- ✅ Empty/null input handling
- ✅ Unicode and special character support
- ✅ Very long line wrapping
- ✅ Error scenarios in pipeline
- ✅ Decorator composition edge cases
- ✅ Filter edge cases
- ✅ FileSink concurrency and rapid logging

## Purpose

These tests ensure the Handler module is robust and handles edge cases gracefully without crashing or producing incorrect output.

