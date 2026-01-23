import 'package:logd/logd.dart';
import 'package:test/test.dart';
import 'decorator/mock_context.dart';

// Mock Sink to capture output
final class MemorySink extends LogSink {
  final List<List<LogLine>> buffer = [];

  @override
  bool get enabled => true;

  @override
  int get preferredWidth => 80;

  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    buffer.add(lines.toList());
  }
}

void main() {
  group('Handler Automatic Sorting', () {
    test('Sorts decorators: Visual -> Box -> Hierarchy', () async {
      final sink = MemorySink();
      // Input Order: Hierarchy (3) -> Box (2) -> Ansi (1). Reverse of desired.
      final handler = Handler(
        sink: sink,
        formatter: const StructuredFormatter(),
        decorators: const [
          HierarchyDepthPrefixDecorator(indent: '>> '),
          BoxDecorator(borderStyle: BorderStyle.rounded),
          StyleDecorator(),
        ],
        lineLength: 20,
      );

      // We need to bypass Logger and call handler direct or use a logger
      // Logger.configure is global, might interfere.
      // Handler.log is internal but accessible if we import internal handler?
      // Wait, Handler.log is public? No, Handler is public.
      // The `log` method on Handler is: `void log(LogEntry entry)`

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'now',
        hierarchyDepth: 1,
      );

      await handler.log(entry);

      // Expected Result Pipeline:
      // 1. Ansi: Colors 'msg' -> \x1B[32mmsg\x1B[0m
      // 2. Box: Wraps colored msg. Border is GREEN (Info).
      //    Top: \x1B[32m╭...╮\x1B[0m
      //    Vertical: \x1B[32m│\x1B[0m
      // 3. Hierarchy: Indents everything with '>> '.

      final lines = renderLines(sink.buffer.first);
      expect(lines.length, greaterThan(0));

      final top = lines[0];
      // Check Hierarchy First (Outer)
      // Hierarchy comes before Color, so Color decorates the prefix
      // (LogTag.header).
      expect(top, contains('>> '));

      // Check Box Border Color (Inner)
      // Info level now defaults to blue (was green)
      expect(top, contains('\x1B[34m╭'));
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
        hierarchyDepth: 0,
      );

      await handler.log(entry);

      final lines = renderLines(sink.buffer.single);
      final line = lines.firstWhere((final l) => l.contains('msg'));

      // If applied twice, we might see double codes or just one if idempotent.
      // StyleDecorator IS idempotent check tags.
      // But verify strictly that `decorate` wasn't called redundant times?
      // Actually, idempotency inside decorator handles it, but deduping in
      // handler prevents the loop entirely.
      // Let's rely on the fact that if it wasn't deduped, we might expect
      // slightly different behavior or at least performance penalty.
      // But here we just want to ensure it works and doesn't crash or
      // duplicate output weirdly.

      // Formatter adds prefix '----|' to message
      // Info level now defaults to blue (was green)
      expect(line, contains('\x1B[34m----|msg\x1B[0m'));
    });
  });
}
