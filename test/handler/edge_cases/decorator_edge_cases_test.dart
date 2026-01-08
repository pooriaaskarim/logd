import 'package:logd/logd.dart';
import 'package:test/test.dart';

import '../decorator/mock_context.dart';

void main() {
  group('Decorator Edge Cases', () {
    test('handles duplicate decorators (deduplication)', () async {
      final sink = _MemorySink();
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        decorators: const [
          const ColorDecorator(),
          const ColorDecorator(), // Duplicate
          const ColorDecorator(), // Duplicate
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
          const ColorDecorator(),
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

      final formatted = handler.formatter.format(entry, mockContext);
      final decorated = handler.decorators.first
          .decorate(formatted, entry, mockContext)
          .toList();

      // Should handle gracefully
      expect(decorated, isA<List<LogLine>>());
    });

    // Idempotency tests removed as new architecture doesn't enforce it via tags currently.
    // BoxDecorator doesn't check for prior boxing (allows nesting).
    // ColorDecorator re-applies styles (idempotent in effect/overwrite).

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
          ),
          const ColorDecorator(),
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
      expect(output.first.toString(), startsWith('>> '));
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
