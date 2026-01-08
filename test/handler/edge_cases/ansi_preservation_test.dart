import 'package:logd/logd.dart';
import 'package:logd/src/core/utils.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('ANSI Code Preservation', () {
    test('preserves ANSI codes when wrapping long colored text', () {
      const formatter = PlainFormatter();
      const handler = Handler(
        formatter: formatter,
        decorators: [
          const ColorDecorator(),
        ],
        sink: ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This is a very long message that will definitely wrap across '
            'multiple lines when formatted and ANSI color codes should '
            'be preserved throughout the wrapping process',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = formatter.format(entry, mockContext).toList();
      expect(formatted.length, greaterThanOrEqualTo(1));

      // Apply decorator
      final decorated = handler.decorators.first
          .decorate(formatted, entry, mockContext)
          .toList();

      // Check that all wrapped lines have ANSI codes
      // renderLines simulates the Sink rendering with ANSI enabled
      final rendered = renderLines(decorated);

      for (final line in rendered) {
        // All non-empty lines should have ANSI codes (blue = \x1B[34m)
        if (line.isNotEmpty) {
          expect(line, contains('\x1B[34m'));
        }
        // Last non-empty line should end with reset
        final lastNonEmpty = rendered.lastWhere((final l) => l.isNotEmpty);
        if (line == lastNonEmpty && line.isNotEmpty) {
          expect(line, endsWith('\x1B[0m'));
        }
      }
    });

    test('preserves ANSI codes in box decorator with wrapping', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 40),
        decorators: [
          const ColorDecorator(),
          BoxDecorator(
            borderStyle: BorderStyle.rounded,
            lineLength: 40,
          ),
        ],
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.warning,
        message:
            'This is a very long warning message that will wrap inside the box',
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

      // Find content lines (not borders)
      final contentLines = rendered.where(
        (final line) =>
            line.contains('│') &&
            !line.startsWith('╭') &&
            !line.startsWith('╰'),
      );

      // Content lines should preserve ANSI codes
      for (final line in contentLines) {
        // Should contain ANSI code for warning (yellow = \x1B[33m)
        expect(line, contains('\x1B[33m'));
      }
    });

    test('handles multiple ANSI codes in sequence', () {
      // Test with text that already has ANSI codes
      const textWithCodes = '\x1B[1m\x1B[34mBold Blue Text\x1B[0m';
      final result = textWithCodes.wrapVisiblePreserveAnsi(10).toList();

      expect(result.length, greaterThan(1));
      // All lines should preserve the ANSI prefix
      for (final line in result) {
        expect(line, startsWith('\x1B[1m\x1B[34m'));
      }
      // Last line should have reset
      expect(result.last, endsWith('\x1B[0m'));
    });

    test('handles empty string with ANSI codes', () {
      const emptyWithCodes = '\x1B[34m\x1B[0m';
      final result = emptyWithCodes.wrapVisiblePreserveAnsi(10).toList();

      expect(result.length, equals(1));
      expect(result.first, equals(emptyWithCodes));
    });
  });
}
