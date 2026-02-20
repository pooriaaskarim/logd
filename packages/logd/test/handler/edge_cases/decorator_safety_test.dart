import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

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
          BoxDecorator(borderStyle: BorderStyle.rounded),
          StyleDecorator(),
        ],
        sink: sink,
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      await handler.log(entry);
      final output = sink.outputs.first;
      // Depth prefix should be outermost
      expect(output.first, startsWith('>> '));
    });

    test('BoxDecorator handles very small lineLength', () {
      const box = BoxDecorator();
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      final lines = ['very long message that exceeds 5 chars'];
      final doc = createTestDocument(lines);
      final decorated = box.decorate(doc, entry);

      const layout = TerminalLayout(width: 5);
      final boxed = layout.layout(decorated, LogLevel.info).lines;

      expect(boxed, isNotEmpty);
      final topWidth = boxed[0].visibleLength;
      for (final line in boxed) {
        expect(line.visibleLength, equals(topWidth));
      }
    });

    test('BoxDecorator handles lines with only ANSI codes', () {
      const box = BoxDecorator();
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      final lines = ['\x1B[31m\x1B[0m']; // Red color then reset
      final doc = createTestDocument(lines);
      final decorated = box.decorate(doc, entry);

      const layout = TerminalLayout(width: 20);
      final boxed = layout.layout(decorated, LogLevel.info).lines;
      expect(boxed, isNotEmpty);
    });
  });
}

final class _MemorySink extends LogSink<LogDocument> {
  _MemorySink();
  final List<List<String>> outputs = [];

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
  ) async {
    const encoder = PlainTextEncoder();
    final output = encoder.encode(entry, document, level, width: 80);
    outputs.add(output.split('\n'));
  }
}
