import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('Very Long Lines Handling', () {
    test('wraps extremely long single line', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 40),
        sink: const ConsoleSink(),
      );

      final longMessage = 'word ' * 100; // 500 characters
      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: longMessage,
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext).toList();
      // Should wrap into multiple lines
      expect(formatted.length, greaterThan(1));
      // All lines should respect line length
      for (final line in formatted) {
        expect(line.visibleLength, lessThanOrEqualTo(40));
      }
    });

    test('handles very long word without spaces', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 20),
        decorators: [
          BoxDecorator(
            borderStyle: BorderStyle.rounded,
            lineLength: 20,
          ),
        ],
        sink: const ConsoleSink(),
      );

      final longWord = 'a' * 100; // 100 character word
      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: longWord,
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, mockContext);
      }

      final result = lines.toList();
      final topWidth = result[0].visibleLength;
      // Box should maintain consistent width
      for (final line in result) {
        expect(line.visibleLength, equals(topWidth));
      }
    });

    test('preserves ANSI codes in very long wrapped text', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 30),
        decorators: const [
          ColorDecorator(),
        ],
        sink: const ConsoleSink(),
      );

      final longMessage = 'This is a very long message ' * 10;
      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.error,
        message: longMessage,
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, mockContext);
      }

      final result = lines.toList();
      final rendered = renderLines(result);

      // Find message lines (those with '----|')
      final messageLines = rendered.where(
        (final line) => line.contains('----|'),
      );

      // All message lines should have ANSI codes (error = red = \x1B[31m)
      for (final line in messageLines) {
        expect(line, contains('\x1B[31m'));
      }
    });

    test('handles multi-line input with very long lines', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 40),
        sink: const ConsoleSink(),
      );

      const multiLineMessage = '''
This is the first line which is normal length
This is a very long second line that definitely exceeds the line length limit and should be wrapped properly
Short third line
Another very long fourth line that also needs wrapping because it exceeds the maximum line length
''';

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: multiLineMessage,
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext).toList();
      // Should handle all lines
      expect(formatted.length, greaterThan(4));
      // All lines should respect line length
      for (final line in formatted) {
        expect(line.visibleLength, lessThanOrEqualTo(40));
      }
    });

    test('box decorator handles very long content', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 30),
        decorators: [
          BoxDecorator(
            borderStyle: BorderStyle.sharp,
            lineLength: 30,
          ),
        ],
        sink: const ConsoleSink(),
      );

      final longContent = 'x' * 200; // 200 characters
      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: longContent,
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, mockContext);
      }

      final result = lines.toList();
      final topWidth = result[0].visibleLength;
      // All lines should have consistent width
      for (final line in result) {
        expect(line.visibleLength, equals(topWidth));
      }
    });
  });
}
