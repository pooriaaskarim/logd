import 'package:logd/logd.dart';
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
      hierarchyDepth: 0,
    );

    test('Output header once then rows with TAB delimiter (default)', () {
      final formatter = ToonFormatter();

      final lines = formatter
          .format(entry, mockContext)
          .map((final l) => l.toString())
          .toList();

      expect(lines.length, equals(2)); // Header + Row
      expect(
        lines[0],
        equals('logs[]{timestamp,level,logger,message,error}:'),
      );
      // Default: Tab delimiter
      expect(
        lines[1],
        equals('"2025-01-01T10:00:00Z"\tinfo\ttest\tmsg\t'),
      );
    });

    test('Respects custom delimiter and keys (normalized Enum)', () {
      final formatter = ToonFormatter(
        delimiter: ',',
        arrayName: 'events',
        keys: [LogField.level, LogField.message],
      );
      final lines = formatter
          .format(entry, mockContext)
          .map((final l) => l.toString())
          .toList();

      expect(
        lines[0],
        equals('events[]{level,message}:'),
      );
      expect(lines[1], equals('info,msg'));
    });

    test('Colorize=true emits semantic tags', () {
      final formatter = ToonFormatter(
        keys: [LogField.level, LogField.message],
        colorize: true,
      );
      final lines = formatter.format(entry, mockContext).toList();

      // Header should have header tags
      final headerSegs = lines[0].segments;
      expect(headerSegs.length, equals(1));
      expect(headerSegs[0].tags, contains(LogTag.header));

      // Row should be segmented
      // [Level, Delimiter, Message]
      final rowSegs = lines[1].segments;
      expect(rowSegs.length, equals(3)); // Level, Delimiter, Message

      // Level segment
      expect(rowSegs[0].text, equals('info'));
      expect(rowSegs[0].tags, contains(LogTag.level));

      // Delimiter segment
      expect(rowSegs[1].text, equals('\t'));
      expect(rowSegs[1].tags, contains(LogTag.border));

      // Message segment
      expect(rowSegs[2].text, equals('msg'));
      expect(rowSegs[2].tags, contains(LogTag.message));
    });

    test('Quotes values containing delimiter', () {
      final formatter = ToonFormatter(delimiter: ',');
      const entryWithComma = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'Hello, World', // Has comma
        timestamp: 'now',
        hierarchyDepth: 0,
      );

      final lines = formatter
          .format(entryWithComma, mockContext)
          .map((final l) => l.toString())
          .toList();
      // "Hello, World" should be quoted
      expect(lines[1], contains(',"Hello, World",'));
    });
  });
}
