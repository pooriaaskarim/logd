---
name: dart-add-unit-test
description: Write and organize unit tests for logd formatters, decorators, and execution engines using package:test to assert correct output and prevent regressions.
---
# Writing Unit Tests for logd

## Principles
1. **Engine Parity**: Every change to formatting, decoration, or layout rendering MUST be verified under both standard and pooled paths. Use the parity test helpers.
2. **Deterministic Inputs**: Standardize timestamps, process names, and system environments (e.g. timezone offsets) in tests to guarantee repeatable test outputs.
3. **No Thread Blocks**: Ensure FFI and isolate worker tests handle backpressure, dispose ports, and terminate workers cleanly in `tearDown()`.

## Example Assertions
```dart
import 'package:logd/logd.dart';
import 'package:logd/testing.dart';
import 'package:test/test.dart';

void main() {
  late TestLogger logger;

  setUp(() {
    logger = TestLogger('app.test');
  });

  tearDown(() async {
    await logger.dispose();
  });

  test('should format info logs correctly', () {
    logger.info('hello world');
    expect(logger, hasLog(level: LogLevel.info, message: 'hello world'));
  });
}
```
