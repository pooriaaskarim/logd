// Tests for negative width handling in formatters and decorators.
import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Negative Width Handling', () {
    test('StructuredFormatter handles very small lineLength', () {
      // Very small lineLength that could cause negative innerWidth
      final formatter = StructuredFormatter(lineLength: 3);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // Should not crash with negative width
      final lines = formatter.format(entry).toList();
      expect(lines, isNotEmpty);
    });

    test('BoxDecorator handles very small lineLength', () {
      // lineLength of 3 is minimum (borders + 1 char content)
      final box = BoxDecorator(lineLength: 3);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'x',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = [LogLine.plain('x')];
      // Should not crash
      expect(() => box.decorate(formatted, entry).toList(), returnsNormally);
    });

    test('BoxDecorator rejects lineLength less than 3', () {
      expect(
        () => BoxDecorator(lineLength: 2),
        throwsArgumentError,
      );
      expect(
        () => BoxDecorator(lineLength: 1),
        throwsArgumentError,
      );
      expect(
        () => BoxDecorator(lineLength: 0),
        throwsArgumentError,
      );
    });
  });
}
