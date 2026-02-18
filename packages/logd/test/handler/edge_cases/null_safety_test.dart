// Tests for null safety, empty messages, and corner cases across formatters
// and decorators.
import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('Null Safety & Empty Handling', () {
    test('StructuredFormatter handles null error and stackTrace gracefully',
        () {
      const formatter = StructuredFormatter();
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.error,
        message: 'Error occurred',
        timestamp: '2025-01-01 10:00:00',
        error: null,
        stackTrace: null,
      );

      final lines = formatter.format(entry, mockContext).toList();
      expect(lines, isNotEmpty);
      expect(lines.any((final l) => l.toString().contains('Error:')), isFalse);
    });

    test('StructuredFormatter handles very long logger name by wrapping header',
        () {
      const formatter = StructuredFormatter();
      const context = LogContext(availableWidth: 40);
      const entry = LogEntry(
        loggerName: 'very_long_logger_name_that_exceeds_line_length',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      final lines = formatter.format(entry, context).toList();
      expect(lines, isNotEmpty);
      for (final line in lines) {
        expect(line.visibleLength, lessThanOrEqualTo(60));
      }
      expect(
        lines.any((final l) => l.toString().contains('very_long_logge')),
        isTrue,
      );
    });

    test('BoxDecorator handles single-character or empty message gracefully',
        () {
      const handler = Handler(
        formatter: StructuredFormatter(),
        decorators: [
          BoxDecorator(borderStyle: BorderStyle.rounded),
        ],
        sink: ConsoleSink(),
        lineLength: 40,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'x',
        timestamp: '2025-01-01 10:00:00',
      );

      const context = LogContext(availableWidth: 40);
      final formatted = handler.formatter.format(entry, context);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, context);
      }

      final result = resultLines(lines);
      expect(result.length, greaterThanOrEqualTo(3)); // Box should still form
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
