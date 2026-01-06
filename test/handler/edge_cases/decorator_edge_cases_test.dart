// Tests for decorator edge cases and composition.
import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Decorator Edge Cases', () {
    test('handles duplicate decorators (deduplication)', () async {
      final sink = _MemorySink();
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        decorators: const [
          AnsiColorDecorator(useColors: true),
          AnsiColorDecorator(useColors: true), // Duplicate
          AnsiColorDecorator(useColors: true), // Duplicate
        ],
        sink: sink,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test message',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      await handler.log(entry);

      // Should process without errors
      expect(sink.outputs, isNotEmpty);
    });

    test('handles empty decorator list', () async {
      final sink = _MemorySink();
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        decorators: const [], // Empty
        sink: sink,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test message',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      await handler.log(entry);

      expect(sink.outputs, isNotEmpty);
    });

    test('handles decorator with empty input lines', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        decorators: const [
          AnsiColorDecorator(useColors: true),
        ],
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry);
      final decorated =
          handler.decorators.first.decorate(formatted, entry).toList();

      // Should handle gracefully
      expect(decorated, isA<List<LogLine>>());
    });

    test('box decorator handles already-boxed lines (idempotency)', () {
      final box = BoxDecorator(
        borderStyle: BorderStyle.rounded,
        lineLength: 40,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // First application
      final formatted = [LogLine.plain('test')];
      final firstBoxed = box.decorate(formatted, entry).toList();

      // Verify first application created a box
      expect(
        firstBoxed.length,
        greaterThanOrEqualTo(3),
      ); // top, content, bottom
      expect(firstBoxed[0].text, contains('╭')); // Top border
      expect(firstBoxed.last.text, contains('╰')); // Bottom border

      // Second application (should skip already-boxed lines)
      final secondBoxed = box.decorate(firstBoxed, entry).toList();

      // Should not create nested boxes - already-boxed lines are yielded as-is
      // The result should be same or fewer lines (no additional wrapping should
      // occur)
      expect(secondBoxed.length, lessThanOrEqualTo(firstBoxed.length));

      // Count border characters (╭, ╮, ╰, ╯)
      final borderCount = secondBoxed
          .where(
            (final line) =>
                line.text.contains('╭') ||
                line.text.contains('╮') ||
                line.text.contains('╰') ||
                line.text.contains('╯'),
          )
          .length;

      // Should have exactly 2 borders (top and bottom), not 4
      // (which would indicate nesting)
      expect(borderCount, equals(2));
    });

    test('ansi decorator handles already-colored lines (idempotency)', () {
      const decorator = AnsiColorDecorator(useColors: true);

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // First application
      final plain = [LogLine.plain('test')];
      final firstColored = decorator.decorate(plain, entry).toList();

      // Verify first application added the ansiColored tag
      expect(
        firstColored.first.tags.contains(LogLineTag.ansiColored),
        isTrue,
        reason: 'First application should add ansiColored tag',
      );

      // Second application (should skip already-colored)
      final secondColored = decorator.decorate(firstColored, entry).toList();

      // Should not double-apply colors - lines should remain unchanged
      expect(
        secondColored.first.text,
        equals(firstColored.first.text),
        reason: 'Second application should not modify already-colored lines',
      );

      // Tag should still be present
      expect(
        secondColored.first.tags.contains(LogLineTag.ansiColored),
        isTrue,
        reason: 'ansiColored tag should be preserved',
      );
    });

    test('decorator auto-sorting works with mixed types', () async {
      final sink = _MemorySink();
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 60),
        decorators: [
          // Intentionally wrong order - should be auto-sorted
          const HierarchyDepthPrefixDecorator(indent: '>> '),
          BoxDecorator(
            borderStyle: BorderStyle.rounded,
            lineLength: 60,
            useColors: false,
          ),
          const AnsiColorDecorator(useColors: true),
        ],
        sink: sink,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test message',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 1,
      );

      await handler.log(entry);

      final output = sink.outputs.first;
      // Hierarchy should be outermost (first in output)
      // The decorator uses indent = '>> ' so depth=1 becomes '>> '
      expect(output.first.text, startsWith('>> '));
    });
  });
}

final class _MemorySink extends LogSink {
  final List<List<LogLine>> outputs = [];

  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    outputs.add(lines.toList());
  }
}
