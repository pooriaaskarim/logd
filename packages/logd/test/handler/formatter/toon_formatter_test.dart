import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('ToonFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: '2025-01-01T10:00:00Z',
    );

    test('Output header once then rows with TAB delimiter (default)', () {
      const formatter = ToonFormatter();
      final doc = formatter.format(entry, LogArena.instance);
      final lines = renderToon(doc, entry, LogLevel.info);

      // Header includes: timestamp,logger,origin,level,message,error,stackTrace
      expect(lines.length, equals(2));
      expect(
        lines[0],
        equals(
          'logs[]{timestamp,logger,origin,level,message,error,stackTrace}:',
        ),
      );

      // Row
      expect(
        lines[1],
        equals('"2025-01-01T10:00:00Z"\ttest\ttest\tINFO\tmsg\t\t'),
      );
    });

    test('Respects custom metadata selection', () {
      const formatter = ToonFormatter(metadata: {LogMetadata.logger});
      final doc = formatter.format(entry, LogArena.instance);
      final lines = renderToon(doc, entry, LogLevel.info);

      expect(
        lines[0],
        equals('logs[]{logger,level,message,error,stackTrace}:'),
      );
      expect(lines[1], equals('test\tINFO\tmsg\t\t'));
    });

    test('ToonPrettyFormatter recursively formats Map/List', () {
      const formatter = ToonPrettyFormatter(metadata: {});
      const complexEntry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'ts',
        error: {
          'a': 1,
          'b': [2, 3],
        },
      );

      final doc = formatter.format(complexEntry, LogArena.instance);
      final lines = renderToon(doc, complexEntry, LogLevel.info);
      // INFO \t msg \t {a:1,b:[2,3]} \t
      expect(lines[1], contains('{a:1,b:[2,3]}'));
    });

    test('ToonPrettyFormatter respects sortKeys', () {
      const formatter = ToonPrettyFormatter(metadata: {}, sortKeys: true);
      const complexEntry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'ts',
        error: {'z': 1, 'a': 2},
      );

      final doc = formatter.format(complexEntry, LogArena.instance);
      final lines = renderToon(doc, complexEntry, LogLevel.info);
      expect(lines[1], contains('{a:2,z:1}'));
    });

    test('ToonPrettyFormatter respects maxDepth', () {
      const formatter = ToonPrettyFormatter(metadata: {}, maxDepth: 1);
      const complexEntry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'ts',
        error: {
          'a': {'b': 1},
        },
      );

      final doc = formatter.format(complexEntry, LogArena.instance);
      final lines = renderToon(doc, complexEntry, LogLevel.info);
      expect(lines[1], contains('{a:...}'));
    });
  });
}

List<String> renderToon(
  final LogDocument doc,
  final LogEntry entry,
  final LogLevel level,
) {
  const encoder = ToonEncoder();
  final header = encoder.preamble(level, document: doc);
  final row = encoder.encode(entry, doc, level);

  return [
    if (header != null) header,
    row,
  ];
}
