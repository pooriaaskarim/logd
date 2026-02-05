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

      final structure = formatter.format(entry, mockContext);
      final lines = renderLines(structure);
      expect(lines, isNotEmpty);
      expect(lines.any((final l) => l.contains('Error:')), isFalse);
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

      final structure = formatter.format(entry, context);
      final lines = renderLines(structure);
      expect(lines, isNotEmpty);
      // We don't check visibleLength directly on LogTree here as it depends on
      // encoder,
      // but we check that content is present.
      expect(
        lines.any((final l) => l.contains('very_long_logge')),
        isTrue,
      );
    });

    test('BoxDecorator handles single-character or empty message gracefully',
        () {
      const handler = Handler(
        formatter: StructuredFormatter(),
        decorators: [
          BoxDecorator(border: BoxBorderStyle.rounded),
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
      var structure = handler.formatter.format(entry, context);
      for (final decorator in handler.decorators) {
        structure = decorator.decorate(structure, entry, context);
      }

      final result = renderLines(structure);
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

      final structure = formatter.format(entry, mockContext);
      final json = renderLines(structure).join('\n');
      expect(json, isNot(contains('"error":')));
    });
  });
}
