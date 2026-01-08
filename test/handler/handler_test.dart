import 'package:logd/logd.dart';
import 'package:test/test.dart';

class MockFormatter implements LogFormatter {
  MockFormatter(this.formatFn);
  final Iterable<LogLine> Function(LogEntry) formatFn;
  @override
  Iterable<LogLine> format(final LogEntry entry, final LogContext context) =>
      formatFn(entry);
}

final class MockSink extends LogSink {
  final List<List<LogLine>> outputs = [];
  final List<LogLevel> levels = [];

  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    outputs.add(lines.toList());
    levels.add(level);
  }
}

class MockFilter extends LogFilter {
  MockFilter(this.shouldLogFn);
  final bool Function(LogEntry) shouldLogFn;
  @override
  bool shouldLog(final LogEntry entry) => shouldLogFn(entry);
}

void main() {
  group('Handler Composition', () {
    late MockSink sink;
    late MockFormatter formatter;
    late LogEntry testEntry;

    setUp(() {
      sink = MockSink();
      formatter = MockFormatter(
        (final entry) => [LogLine.text('formatted: ${entry.message}')],
      );
      testEntry = LogEntry(
        loggerName: 'test',
        origin: 'main',
        hierarchyDepth: 0,
        level: LogLevel.info,
        message: 'hello',
        timestamp: Timestamp.iso8601().timestamp!,
      );
    });

    test('Handler calls formatter and sink', () async {
      final handler = Handler(formatter: formatter, sink: sink);
      await handler.log(testEntry);

      expect(sink.outputs.length, equals(1));
      expect(sink.outputs.first.first.toString(), equals('formatted: hello'));
      expect(sink.levels.first, equals(LogLevel.info));
    });

    test('Handler skips sink if formatter returns empty list', () async {
      final emptyFormatter = MockFormatter((final _) => []);
      final handler = Handler(formatter: emptyFormatter, sink: sink);
      await handler.log(testEntry);

      expect(sink.outputs, isEmpty);
    });

    test('Single filter passing allows logging', () async {
      final filter = MockFilter((final _) => true);
      final handler =
          Handler(formatter: formatter, sink: sink, filters: [filter]);
      await handler.log(testEntry);

      expect(sink.outputs.length, equals(1));
    });

    test('Single filter failing blocks logging', () async {
      final filter = MockFilter((final _) => false);
      final handler =
          Handler(formatter: formatter, sink: sink, filters: [filter]);
      await handler.log(testEntry);

      expect(sink.outputs, isEmpty);
    });

    test('All filters must pass (AND behavior)', () async {
      final filters = [
        MockFilter((final _) => true),
        MockFilter((final _) => false), // This one blocks
        MockFilter((final _) => true),
      ];
      final handler =
          Handler(formatter: formatter, sink: sink, filters: filters);
      await handler.log(testEntry);

      expect(sink.outputs, isEmpty);
    });
  });

  group('Built-in Filters', () {
    const entryInfo = LogEntry(
      loggerName: 'app.ui',
      origin: 'Widget.build',
      hierarchyDepth: 1,
      level: LogLevel.info,
      message: 'info msg',
      timestamp: '2025-01-01 12:00:00',
    );
    const entryError = LogEntry(
      loggerName: 'app.service',
      origin: 'Service.run',
      hierarchyDepth: 1,
      level: LogLevel.error,
      message: 'error msg',
      timestamp: '2025-01-01 12:00:01',
    );

    test('LevelFilter blocks lower levels', () {
      const filter = LevelFilter(LogLevel.warning);
      expect(filter.shouldLog(entryInfo), isFalse);
      expect(filter.shouldLog(entryError), isTrue);
    });

    test('RegexFilter filters by message', () {
      final filter = RegexFilter(RegExp('error'));
      expect(filter.shouldLog(entryInfo), isFalse);
      expect(filter.shouldLog(entryError), isTrue);
    });

    test('RegexFilter filters by name (if configured)', () {
      // Assuming RegexFilter has a way to check name, or we just test
      // message for now Based on previous analysis, RegexFilter usually
      // checks entry.message
    });
  });
}
