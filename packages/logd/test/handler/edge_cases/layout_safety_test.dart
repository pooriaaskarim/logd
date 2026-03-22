import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('Layout & Encoding Safety', () {
    test('Unicode and Emoji handle widths correctly in BoxDecorator', () {
      const box = BoxDecorator(borderStyle: BorderStyle.rounded);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '你好世界 🌍',
        timestamp: '2025-01-01 10:00:00',
      );

      final lines = ['你好世界 🌍', 'ASCII Test'];
      final doc = createTestDocument(lines);
      try {
        box.decorate(doc, entry, LogArena.instance);

        const layout = TerminalLayout(width: 40);
        final result = layout.layout(doc, LogLevel.info).lines;

        final topWidth = result[0].visibleLength;
        for (final line in result) {
          expect(
            line.visibleLength,
            equals(topWidth),
            reason: 'Line failed: $line',
          );
        }
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('ANSI preservation across wrapping in BoxDecorator', () {
      const box = BoxDecorator(borderStyle: BorderStyle.double);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      // Colored message
      final lines = ['\x1B[31mThis is red\x1B[0m'];
      final doc = createTestDocument(lines);
      try {
        box.decorate(doc, entry, LogArena.instance);

        const layout = TerminalLayout(width: 20);
        final result = layout.layout(doc, LogLevel.info).lines;

        expect(result.length, equals(4));
        // Each wrapped line should start with red color (if preserved)
        // Note: Current naive implementation preserves ANSI at start of each
        // wrap
        expect(result[1].toString(), contains('\x1B[31m'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('Very long words without spaces are forced to wrap', () {
      const formatter = StructuredFormatter();
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'Supercalifragilisticexpialidocious',
        timestamp: '2025-01-01 10:00:00',
      );

      final doc = formatDoc(formatter, entry);
      try {
        const layout = TerminalLayout(width: 20);
        final lines = layout.layout(doc, LogLevel.info).lines;
        for (final line in lines) {
          expect(line.visibleLength, lessThanOrEqualTo(20));
        }
        final json = lines.map((final l) => l.toString()).join('\n');
        expect(json, isNot(contains('"error":')));
        expect(lines.length, greaterThan(3));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('Malformed ANSI codes do not crash the system', () {
      final lines = ['Normal \x1B[999;999;999m Malformed'];
      // Should not crash visibleLength calculation
      // We can use TerminalLayout to simulate rendering which calculates
      // visibleLength
      const layout = TerminalLayout(width: 80);
      final doc = createTestDocument(lines);
      try {
        final physical = layout.layout(doc, LogLevel.info);
        expect(physical.lines.first.visibleLength, isPositive);
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });
}
