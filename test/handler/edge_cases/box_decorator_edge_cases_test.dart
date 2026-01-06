// Tests for BoxDecorator edge cases that might cause issues.
import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('BoxDecorator Edge Cases', () {
    test('handles very small lineLength', () {
      final box = BoxDecorator(lineLength: 5); // Very small
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = [LogLine.plain('test message')];
      final boxed = box.decorate(formatted, entry).toList();

      // Should not crash, should handle gracefully
      expect(boxed, isNotEmpty);
      // All lines should have consistent width
      final topWidth = boxed[0].visibleLength;
      for (final line in boxed) {
        expect(line.visibleLength, equals(topWidth));
      }
    });

    test('handles lines with only ANSI codes', () {
      final box = BoxDecorator(lineLength: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // Line with only ANSI codes
      final formatted = [const LogLine('\x1B[34m\x1B[0m')];
      final boxed = box.decorate(formatted, entry).toList();

      expect(boxed, isNotEmpty);
    });

    test('handles lines with newlines in text', () {
      final box = BoxDecorator(lineLength: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // Line with embedded newlines
      final formatted = [const LogLine('line1\nline2\nline3')];
      final boxed = box.decorate(formatted, entry).toList();

      // Should split into multiple boxed lines
      expect(boxed.length, greaterThan(3)); // top, 3 content lines, bottom
    });

    test('handles empty lines list', () {
      final box = BoxDecorator(lineLength: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = <LogLine>[];
      final boxed = box.decorate(formatted, entry).toList();

      // Should produce at least top and bottom borders
      expect(boxed.length, greaterThanOrEqualTo(2));
    });
  });
}
