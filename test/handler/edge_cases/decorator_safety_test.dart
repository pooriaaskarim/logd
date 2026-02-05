import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Decorator Safety & Composition', () {
    test('handles duplicate decorators (deduplication)', () async {
      final sink = _MemorySink();
      final handler = Handler(
        formatter: const StructuredFormatter(),
        decorators: const [
          StyleDecorator(),
          StyleDecorator(), // Duplicate
        ],
        sink: sink,
        lineLength: 80,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      await handler.log(entry);
      expect(sink.outputs, isNotEmpty);
    });

    test('handles auto-sorting of decorators', () async {
      final sink = _MemorySink();
      final handler = Handler(
        formatter: const StructuredFormatter(),
        decorators: const [
          // Mixed order
          HierarchyDepthPrefixDecorator(indent: '>> '),
          BoxDecorator(border: BoxBorderStyle.rounded),
          StyleDecorator(),
        ],
        sink: sink,
        lineLength: 60,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      await handler.log(entry);
      final structure = sink.outputs.first;

      const encoder = AnsiEncoder();
      final renderedLines = encoder
          .encode(
            structure.copyWith(metadata: {'width': 60}),
            LogLevel.info,
          )
          .split('\n');

      // outermost decorator (Style) -> wait, sorting is:
      // 1. Content (Suffix) -> 0
      // 2. Structural (Box -> 1, Hierarchy -> 2)
      // 3. Visual (Style) -> 4
      // So Hierarchy (2) is nested inside Box (1) if both are present?
      // Wait, sorting: a=Box (1), b=Hierarchy (2). 1 < 2, so Box is first?
      // No, priority 1 comes before 2 in sort.
      // So Box (1) then Hierarchy (2).
      // This means Hierarchy is "inner" to Box?
      // Outer wrapping: Box (priority 1) comes first in sorted list.
      // `for (final decorator in sortedDecorators) {
      // structure = decorator.decorate(...)
      // }`
      // So Box decorates first, then Hierarchy decorates the Boxed structure.
      // This means Hierarchy is OUTSIDE Box.
      // So '>> ' should be on the outermost lines.
      expect(renderedLines.first, contains('>> '));
    });

    test('BoxDecorator handles very small lineLength', () {
      const box = BoxDecorator();
      const context = LogContext(availableWidth: 5);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      const structure = LogDocument(
        nodes: [
          MessageNode(
            segments: [
              StyledText('very long message that exceeds 5 chars'),
            ],
          ),
        ],
      );
      final boxed = box.decorate(structure, entry, context);

      const encoder = AnsiEncoder();
      final renderedLines = encoder
          .encode(
            boxed.copyWith(metadata: {'width': 5}),
            LogLevel.info,
          )
          .split('\n');

      expect(renderedLines, isNotEmpty);
      // In new model, visibleLength is not on LogLine/String directly in same way
      // But verify line lengths match top border
      // Actually visibleLength implies removing ANSI.
      // But BoxDecorator adds fixed borders.
      // If we assume no multiline wrapping inside the box for this test
      // (or wrapping handles it) Just check lines are consistent.
      expect(renderedLines[0].length, equals(5)); // Width constraint is 5
      // BoxDecorator takes some width.
    });

    test('BoxDecorator handles lines with only ANSI codes', () {
      const box = BoxDecorator();
      const context = LogContext(availableWidth: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      const structure = LogDocument(
        nodes: [
          MessageNode(segments: [StyledText('\x1B[31m\x1B[0m')]),
        ],
      );
      final boxed = box.decorate(structure, entry, context);

      const encoder = AnsiEncoder();
      final renderedLines = encoder
          .encode(
            boxed.copyWith(metadata: {'width': 20}),
            LogLevel.info,
          )
          .split('\n');

      expect(renderedLines, isNotEmpty);
    });
  });
}

final class _MemorySink extends LogSink {
  final List<LogDocument> outputs = [];

  @override
  int get preferredWidth => 80;

  @override
  Future<void> output(
    final LogDocument document,
    final LogLevel level,
  ) async {
    outputs.add(document);
  }
}
