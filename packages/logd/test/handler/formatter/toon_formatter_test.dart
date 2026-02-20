import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../decorator/mock_context.dart';

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

      final lines = renderLines(formatter.format(entry, mockContext));

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
      final lines = renderLines(formatter.format(entry, mockContext));

      expect(
        lines[0],
        equals('logs[]{logger,level,message,error,stackTrace}:'),
      );
      expect(lines[1], equals('test\tINFO\tmsg\t\t'));
    });

    test('Color=true emits semantic tags in ToonPrettyFormatter', () {
      const formatter =
          ToonPrettyFormatter(metadata: {LogMetadata.logger}, color: true);
      const layout = TerminalLayout(width: 80);
      final lines = layout
          .layout(formatter.format(entry, mockContext), LogLevel.info)
          .lines;

      final row = lines[1];
      final rowSegs = row.segments;

      expect(rowSegs[0].text, equals('test'));
      expect(rowSegs[2].tags, contains(LogTag.level));
      expect(rowSegs[2].text, equals('INFO'));
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

      final lines = renderLines(formatter.format(complexEntry, mockContext));
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

      final lines = renderLines(formatter.format(complexEntry, mockContext));
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

      final lines = renderLines(formatter.format(complexEntry, mockContext));
      expect(lines[1], contains('{a:...}'));
    });
  });
}
