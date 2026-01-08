import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('Decorator Safety & Composition', () {
    test('handles duplicate decorators (deduplication)', () async {
      final sink = _MemorySink();
      final handler = Handler(
        formatter: const StructuredFormatter(lineLength: 80),
        decorators: const [
          ColorDecorator(),
          ColorDecorator(), // Duplicate
        ],
        sink: sink,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      await handler.log(entry);
      expect(sink.outputs, isNotEmpty);
    });

    test('handles auto-sorting of decorators', () async {
      final sink = _MemorySink();
      final handler = Handler(
        formatter: const StructuredFormatter(lineLength: 60),
        decorators: [
          // Mixed order
          const HierarchyDepthPrefixDecorator(indent: '>> '),
          BoxDecorator(borderStyle: BorderStyle.rounded, lineLength: 60),
          const ColorDecorator(),
        ],
        sink: sink,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 1,
      );

      await handler.log(entry);
      final output = sink.outputs.first;
      // Depth prefix should be outermost
      expect(output.first.toString(), startsWith('>> '));
    });

    test('BoxDecorator handles very small lineLength', () {
      final box = BoxDecorator(lineLength: 5);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final lines = [LogLine.text('very long message that exceeds 5 chars')];
      final boxed = box.decorate(lines, entry, mockContext).toList();

      expect(boxed, isNotEmpty);
      final topWidth = boxed[0].visibleLength;
      for (final line in boxed) {
        expect(line.visibleLength, equals(topWidth));
      }
    });

    test('BoxDecorator handles lines with only ANSI codes', () {
      final box = BoxDecorator(lineLength: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final lines = [LogLine.text('\x1B[31m\x1B[0m')]; // Red color then reset
      final boxed = box.decorate(lines, entry, mockContext).toList();
      expect(boxed, isNotEmpty);
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
