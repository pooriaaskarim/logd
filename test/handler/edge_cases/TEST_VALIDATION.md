# Edge Case Tests Validation Guide

## Overview

This directory contains comprehensive edge case tests for the Handler module. These tests validate robustness and ensure the module handles various scenarios gracefully.

## Test Files

### 1. `ansi_preservation_test.dart`
**Purpose**: Validates ANSI code preservation during text wrapping and processing.

**Key Tests**:
- Preserves ANSI codes when wrapping long colored text
- Preserves ANSI codes in box decorator with wrapping
- Handles multiple ANSI codes in sequence
- Handles empty strings with ANSI codes

**Expected Behavior**:
- ANSI codes should be preserved across line breaks
- Colors should remain consistent in wrapped text
- Multiple codes should be handled correctly

### 2. `empty_null_handling_test.dart`
**Purpose**: Ensures graceful handling of empty, null, and edge case messages.

**Key Tests**:
- Empty string messages
- Whitespace-only messages
- Very short messages (single character)
- Messages with only newlines
- Empty messages with decorators

**Expected Behavior**:
- No crashes on empty/null input
- Graceful degradation
- Minimal or appropriate output

### 3. `unicode_handling_test.dart`
**Purpose**: Validates Unicode and special character support.

**Key Tests**:
- Unicode characters (Chinese, etc.)
- Emoji support
- Special ASCII characters
- Mixed Unicode and ASCII
- Long Unicode strings with wrapping

**Expected Behavior**:
- Proper character width calculation
- Correct wrapping with Unicode
- Box structure maintained with Unicode
- No encoding issues

### 4. `very_long_lines_test.dart`
**Purpose**: Tests handling of very long lines and wrapping edge cases.

**Key Tests**:
- Extremely long single lines
- Very long words without spaces
- ANSI code preservation in very long wrapped text
- Multi-line input with very long lines
- Box decorator with very long content

**Expected Behavior**:
- Proper wrapping at word boundaries
- Consistent line widths
- ANSI codes preserved
- Box structure maintained

### 5. `error_handling_test.dart`
**Purpose**: Validates error handling in the handler pipeline.

**Key Tests**:
- Formatter exceptions
- Decorator exceptions
- Sink exceptions
- Filter exceptions
- Empty iterable handling

**Expected Behavior**:
- Exceptions propagate correctly (expected)
- No silent failures
- Appropriate error messages

### 6. `decorator_edge_cases_test.dart`
**Purpose**: Tests decorator edge cases and composition.

**Key Tests**:
- Duplicate decorators (deduplication)
- Empty decorator list
- Decorator with empty input lines
- Box decorator idempotency
- ANSI decorator idempotency
- Decorator auto-sorting with mixed types

**Expected Behavior**:
- Duplicate decorators are deduplicated
- Idempotency: applying decorators multiple times is safe
- Auto-sorting works correctly
- Empty lists handled gracefully

### 7. `filter_edge_cases_test.dart`
**Purpose**: Tests filter edge cases and combinations.

**Key Tests**:
- LevelFilter with all log levels
- RegexFilter with empty messages
- RegexFilter with special regex characters
- RegexFilter with invert option
- Multiple filters with edge cases
- Filters with very long messages
- Filters with Unicode characters

**Expected Behavior**:
- All log levels handled correctly
- Empty messages filtered appropriately
- Special characters handled in regex
- Multiple filters work together (AND behavior)

## Running Tests

### All Edge Case Tests
```bash
dart test test/handler/edge_cases/
```

### Specific Test File
```bash
dart test test/handler/edge_cases/ansi_preservation_test.dart
```

### With Verbose Output
```bash
dart test test/handler/edge_cases/ --reporter expanded
```

## Known Behaviors

### Box Decorator Idempotency
When a line already has the `boxed` tag, BoxDecorator yields it directly without processing. This prevents nested boxes.

### ANSI Decorator Idempotency
When a line already has the `ansiColored` tag, ColorDecorator yields it directly without re-applying colors.

### Decorator Auto-Sorting
Decorators are automatically sorted by type:
1. TransformDecorator (0)
2. VisualDecorator (1)
3. StructuralDecorator (2-4)
   - BoxDecorator (2)
   - HierarchyDepthPrefixDecorator (3)
4. Unknown types (5)

### Filter AND Behavior
All filters must return `true` for a log entry to be processed. If any filter returns `false`, processing stops.

## Troubleshooting

### Test Failures

If a test fails:
1. Check the error message for specific details
2. Verify the expected behavior matches the implementation
3. Review the test logic for correctness
4. Check if the behavior changed in recent updates

### Common Issues

1. **ANSI Code Tests**: May fail if terminal doesn't support ANSI
   - Solution: Tests use explicit `useColors: true`

2. **Unicode Tests**: May have issues with character width
   - Solution: Tests verify visible length, not byte length

3. **Box Decorator Tests**: May fail if line length calculation is off
   - Solution: Tests verify consistent width across all lines

## Validation Checklist

Before considering tests complete:
- [ ] All tests pass
- [ ] No linter errors
- [ ] Tests cover all edge cases
- [ ] Test logic matches implementation behavior
- [ ] Error messages are clear
- [ ] Documentation is up to date

## Contributing

When adding new edge case tests:
1. Follow existing test structure
2. Document expected behavior
3. Add to appropriate test file or create new one
4. Update this README
5. Ensure tests pass and have no linter errors

