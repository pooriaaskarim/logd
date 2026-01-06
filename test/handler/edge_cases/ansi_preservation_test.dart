// Tests for ANSI code preservation during wrapping and processing.
import 'package:logd/logd.dart';
import 'package:logd/src/core/utils.dart';
import 'package:test/test.dart';

void main() {
  group('ANSI Code Preservation', () {
    test('preserves ANSI codes when wrapping long colored text', () {
      const formatter = PlainFormatter();
      const handler = Handler(
        formatter: formatter,
        decorators: [
          AnsiColorDecorator(useColors: true),
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

      final formatted = formatter.format(entry).toList();
      expect(formatted.length, greaterThanOrEqualTo(1));

      // Apply decorator
      final decorated =
          handler.decorators.first.decorate(formatted, entry).toList();

      // Check that all wrapped lines have ANSI codes
      // Note: PlainFormatter doesn't add ANSI codes, AnsiColorDecorator
      // applies them
      // So we check that ANSI codes are present in the decorated output
      for (final line in decorated) {
        // All non-empty lines should have ANSI codes (blue = \x1B[34m)
        if (line.text.isNotEmpty) {
          expect(line.text, contains('\x1B[34m'));
        }
        // Last non-empty line should end with reset
        final lastNonEmpty =
            decorated.lastWhere((final l) => l.text.isNotEmpty);
        if (line == lastNonEmpty && line.text.isNotEmpty) {
          expect(line.text, endsWith('\x1B[0m'));
        }
      }
    });

    test('preserves ANSI codes in box decorator with wrapping', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 40),
        decorators: [
          const AnsiColorDecorator(useColors: true),
          BoxDecorator(
            borderStyle: BorderStyle.rounded,
            lineLength: 40,
            useColors: false,
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

      final formatted = handler.formatter.format(entry);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry);
      }

      final result = lines.toList();
      // Find content lines (not borders)
      final contentLines = result.where(
        (final line) =>
            line.text.contains('│') &&
            !line.text.startsWith('╭') &&
            !line.text.startsWith('╰'),
      );

      // Content lines should preserve ANSI codes
      for (final line in contentLines) {
        // Should contain ANSI code for warning (yellow = \x1B[33m)
        expect(line.text, contains('\x1B[33m'));
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
