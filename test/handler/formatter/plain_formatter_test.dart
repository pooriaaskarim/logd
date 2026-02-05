import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('PlainFormatter', () {
    const entry = LogEntry(
      loggerName: 'test.logger',
      origin: 'main.dart:10:5',
      level: LogLevel.info,
      message: 'Hello World',
      timestamp: '2025-01-01 12:00:00',
    );

    test('formats basic entry correctly with default metadata', () {
      const formatter = PlainFormatter();
      final structure = formatter.format(entry, mockContext);
      final rendered = renderLines(structure);

      expect(rendered.length, equals(1));
      expect(
        rendered.first,
        equals(
          '[INFO] 2025-01-01 12:00:00 [test.logger] Hello World',
        ),
      );
    });

    test('can select metadata', () {
      const formatter = PlainFormatter(
        metadata: {LogMetadata.logger},
      );
      final structure = formatter.format(entry, mockContext);
      final rendered = renderLines(structure).first;

      // [INFO] is mandatory
      expect(
        rendered,
        equals('[INFO] [test.logger] Hello World'),
      );
    });

    test('includes error and stack trace', () {
      final errorEntry = LogEntry(
        loggerName: 'test',
        origin: 'main',
        level: LogLevel.error,
        message: 'Kaboom',
        timestamp: 'now',
        error: 'Some error',
        stackTrace: StackTrace.fromString('stack line 1'),
      );

      const formatter = PlainFormatter();
      final structure = formatter.format(errorEntry, mockContext);
      final lines = renderLines(structure);

      // Should have:
      // 1. [ERROR] now [test] Kaboom
      // 2. Error: Some error
      // 3. stack line 1
      expect(lines.length, greaterThanOrEqualTo(3));
      expect(lines.any((final l) => l == 'Error: Some error'), isTrue);
      expect(lines.any((final l) => l.contains('stack line 1')), isTrue);
    });
  });
}
