import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('PlainFormatter', () {
    const entry = LogEntry(
      loggerName: 'test.logger',
      origin: 'main.dart:10:5',
      hierarchyDepth: 1,
      level: LogLevel.info,
      message: 'Hello World',
      timestamp: '2025-01-01 12:00:00',
    );

    test('formats basic entry correctly', () {
      const formatter = PlainFormatter();
      final lines = formatter.format(entry).toList();

      expect(lines.length, equals(1));
      expect(
        lines.first,
        equals('[INFO] 2025-01-01 12:00:00 [test.logger] Hello World'),
      );
    });

    test('can toggle components', () {
      const formatter = PlainFormatter(
        includeLevel: false,
        includeTimestamp: false,
        includeLoggerName: true,
      );
      final lines = formatter.format(entry).toList();

      expect(lines.first, equals('[test.logger] Hello World'));
    });

    test('includes error and stack trace', () {
      final errorEntry = LogEntry(
        loggerName: 'test',
        origin: 'main',
        hierarchyDepth: 0,
        level: LogLevel.error,
        message: 'Kaboom',
        timestamp: 'now',
        error: 'Some error',
        stackTrace: StackTrace.fromString('stack line 1'),
      );

      const formatter = PlainFormatter();
      final lines = formatter.format(errorEntry).toList();

      expect(lines.length, equals(3));
      expect(lines[1], equals('Error: Some error'));
      expect(lines[2], contains('stack line 1'));
    });
  });
}
