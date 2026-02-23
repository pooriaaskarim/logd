import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';
import 'test_helpers.dart';

// Mock Sink to capture output
final class MemorySink extends LogSink<LogDocument> {
  MemorySink() : super(enabled: true);

  final List<LogDocument> buffer = [];

  @override
  Future<void> output(
    final LogDocument data,
    final LogEntry entry,
    final LogLevel level,
  ) async {
    buffer.add(data);
  }
}

void main() {
  group('Handler Automatic Sorting', () {
    test('Sorts decorators: Visual -> Box -> Hierarchy', () async {
      final sink = MemorySink();
      // Input Order: Hierarchy (2) -> Box (1) -> Visual (4).
      // Desired Output: Content(0) -> Box(1) -> Hierarchy(2) -> Visual(4)
      final handler = Handler(
        sink: sink,
        formatter: const StructuredFormatter(),
        decorators: const [
          HierarchyDepthPrefixDecorator(indent: '>> '),
          BoxDecorator(borderStyle: BorderStyle.rounded),
          StyleDecorator(),
        ],
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'now',
      );

      await handler.log(entry);

      // Expected Result Pipeline:
      // 1. Box: Wraps content.
      // 2. Hierarchy: Indents everything with '>> '.
      // 3. Visual: Colors the whole thing.

      final lines = renderLines(sink.buffer.first, width: 20);
      expect(lines.length, greaterThan(0));

      final top = lines[0];

      // Since StyleDecorator (Visual) is outermost (Priority 4), it wraps
      // EVERYTHING. So line starts with ANSI color code. Blue is \x1B[34m.
      expect(top, startsWith('\x1B[34m'));

      // Followed by Hierarchy indent
      expect(top, contains('\x1B[34m>> '));

      // Followed by Box Border
      expect(top.indexOf('╭'), greaterThan(top.indexOf('>> ')));
    });

    test('Dedupes decorators', () async {
      final sink = MemorySink();
      // Input: Two identical StyleDecorators
      final handler = Handler(
        sink: sink,
        formatter: const StructuredFormatter(),
        decorators: const [
          StyleDecorator(),
          StyleDecorator(),
        ],
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'now',
      );

      await handler.log(entry);

      final lines = renderLines(sink.buffer.single);
      final line = lines.firstWhere((final l) => l.contains('msg'));

      // Info level defaults to blue (\x1B[34m)
      // Header '----|' is bold (\x1B[1m)
      expect(line, contains('\x1B[1m\x1B[34m----|\x1B[0m\x1B[34mmsg\x1B[0m'));
    });
  });
}
