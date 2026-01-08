import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('Layout & Encoding Safety', () {
    test('Unicode and Emoji handle widths correctly in BoxDecorator', () {
      final box =
          BoxDecorator(borderStyle: BorderStyle.rounded, lineLength: 40);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '你好世界 🌍',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final lines = [LogLine.text('你好世界 🌍'), LogLine.text('ASCII Test')];
      final result = box.decorate(lines, entry, mockContext).toList();

      final topWidth = result[0].visibleLength;
      for (final line in result) {
        expect(
          line.visibleLength,
          equals(topWidth),
          reason: 'Line failed: $line',
        );
      }
    });

    test('ANSI preservation across wrapping in BoxDecorator', () {
      final box = BoxDecorator(borderStyle: BorderStyle.double, lineLength: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // Colored message
      final lines = [LogLine.text('\x1B[31mThis is red\x1B[0m')];
      final result = box.decorate(lines, entry, mockContext).toList();

      expect(result.length, equals(3));
      // Each wrapped line should start with red color (if preserved)
      // Note: Current naive implementation preserves ANSI at start of each wrap
      expect(result[1].toString(), contains('\x1B[31m'));
    });

    test('Very long words without spaces are forced to wrap', () {
      const formatter = StructuredFormatter(lineLength: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'Supercalifragilisticexpialidocious',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final lines = formatter.format(entry, mockContext).toList();
      for (final line in lines) {
        expect(line.visibleLength, lessThanOrEqualTo(20));
      }
      final json = lines.map((final l) => l.toString()).join('\n');
      expect(json, isNot(contains('"error":')));
      expect(lines.length, greaterThan(3));
    });

    test('Malformed ANSI codes do not crash the system', () {
      final lines = [LogLine.text('Normal \x1B[999;999;999m Malformed')];
      // Should not crash visibleLength calculation
      expect(lines.first.visibleLength, isPositive);
    });
  });
}
