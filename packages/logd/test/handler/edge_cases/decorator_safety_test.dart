import 'dart:convert';
import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
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

      final entry = LogEntry(
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

      final entry = LogEntry(
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
      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      final lines = ['very long message that exceeds 5 chars'];
      final doc = createTestDocument(lines);
      try {
        box.decorate(doc, entry, Arena.instance);

        final layout = TerminalLayout(width: 5, factory: Arena.instance);
        final boxed = layout.layout(doc, LogLevel.info).lines;

        expect(boxed, isNotEmpty);
        final topWidth = boxed[0].visibleLength;
        for (final line in boxed) {
          expect(line.visibleLength, equals(topWidth));
        }
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });

    test('BoxDecorator handles lines with only ANSI codes', () {
      const box = BoxDecorator();
      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
      );

      final lines = ['\x1B[31m\x1B[0m']; // Red color then reset
      final doc = createTestDocument(lines);
      try {
        box.decorate(doc, entry, Arena.instance);

        final layout = TerminalLayout(width: 20, factory: Arena.instance);
        final boxed = layout.layout(doc, LogLevel.info).lines;
        expect(boxed, isNotEmpty);
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
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
    final LogPipelineFactory factory,
  ) async {
    const encoder = PlainTextEncoder();
    final context = factory.checkoutContext();
    encoder.encode(entry, document, level, context, factory, width: 80);
    final output = const Utf8Decoder().convert(context.takeBytes());
    outputs.add(output.trimRight().split('\n'));
  }
}
