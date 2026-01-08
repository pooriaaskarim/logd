// Tests for null safety, empty messages, and corner cases across formatters
// and decorators.
import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('Null Safety & Empty Handling', () {
    test('StructuredFormatter handles null error and stackTrace gracefully',
        () {
      const formatter = StructuredFormatter(lineLength: 80);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.error,
        message: 'Error occurred',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
        error: null,
        stackTrace: null,
      );

      final lines = formatter.format(entry, mockContext).toList();
      expect(lines, isNotEmpty);
      expect(lines.any((final l) => l.toString().contains('Error:')), isFalse);
    });

    test('StructuredFormatter handles very long logger name by wrapping header',
        () {
      const formatter = StructuredFormatter(lineLength: 20);
      const entry = LogEntry(
        loggerName: 'very_long_logger_name_that_exceeds_line_length',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final lines = formatter.format(entry, mockContext).toList();
      expect(lines, isNotEmpty);
      for (final line in lines) {
        expect(line.visibleLength, lessThanOrEqualTo(20));
      }
      expect(
        lines.any((final l) => l.toString().contains('very_long_logge')),
        isTrue,
      );
    });

    test('StructuredFormatter handles empty/whitespace messages', () {
      const formatter = StructuredFormatter(lineLength: 80);
      const entries = [
        LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: '',
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        ),
        LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: '   \n  ',
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        ),
      ];

      for (final entry in entries) {
        final lines = formatter.format(entry, mockContext).toList();
        expect(lines, isNotEmpty);
      }
    });

    test('BoxDecorator handles single-character or empty message gracefully',
        () {
      final handler = Handler(
        formatter: const StructuredFormatter(lineLength: 40),
        decorators: [
          BoxDecorator(borderStyle: BorderStyle.rounded, lineLength: 40),
        ],
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'x',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, mockContext);
      }

      final result = resultLines(lines);
      expect(result.length, greaterThanOrEqualTo(3)); // Box should still form
      // print('Boxed lines: $result');
      expect(result.any((final l) => l.contains('x')), isTrue);
    });

    test('JsonPrettyFormatter handles null error by omitting the field', () {
      const formatter = JsonPrettyFormatter();
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.error,
        message: 'Error',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
        error: null,
      );

      final lines = formatter.format(entry, mockContext).toList();
      final json = lines.map((final l) => l.toString()).join('\n');
      expect(json, isNot(contains('"error":')));
    });
  });
}

List<String> resultLines(final Iterable<LogLine> lines) =>
    lines.map((final l) => l.toString()).toList();
