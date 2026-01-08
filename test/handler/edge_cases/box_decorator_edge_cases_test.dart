import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

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

      final formatted = [LogLine.text('test message')];
      final boxed = box.decorate(formatted, entry, mockContext).toList();

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
      final formatted = [LogLine.text('\x1B[34m\x1B[0m')];
      final boxed = box.decorate(formatted, entry, mockContext).toList();

      expect(boxed, isNotEmpty);
    });

    test(
        'handles lines with newlines in text (treated as single line by Decorator)',
        () {
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
      // Note: BoxDecorator does NOT split newlines. It wraps what it gets.
      // If Formatter didn't split, Box will render garbage. Ideally we check it doesn't crash.
      final formatted = [LogLine.text('line1\nline2\nline3')];
      final boxed = box.decorate(formatted, entry, mockContext).toList();

      expect(boxed, isNotEmpty);
      // We don't check length > 3 because we don't split anymore.
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
      final boxed = box.decorate(formatted, entry, mockContext).toList();

      // Should produce at least top and bottom borders
      expect(boxed.length, greaterThanOrEqualTo(2));
    });
  });
}
