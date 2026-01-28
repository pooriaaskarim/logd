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
      
    );

    test('Output header once then rows with TAB delimiter (default)', () {
      const formatter = ToonFormatter();

      final lines = formatter
          .format(entry, mockContext)
          .map((final l) => l.toString())
          .toList();

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
        equals('"2025-01-01T10:00:00Z"\ttest\ttest\tinfo\tmsg\t\t'),
      );
    });

    test('Respects custom metadata selection', () {
      const formatter = ToonFormatter(
        metadata: {LogMetadata.logger},
      );
      final lines = formatter
          .format(entry, mockContext)
          .map((final l) => l.toString())
          .toList();

      expect(
        lines[0],
        equals('logs[]{logger,level,message,error,stackTrace}:'),
      );
      expect(lines[1], equals('test\tinfo\tmsg\t\t'));
    });

    test('Color=true emits semantic tags including metadata tags', () {
      const formatter = ToonFormatter(
        metadata: {LogMetadata.logger},
        color: true,
      );
      final lines = formatter.format(entry, mockContext).toList();

      // Row is index 1
      final row = lines[1];
      final rowSegs = row.segments;

      // Delimiter \t is at index 1
      expect(rowSegs[0].text, equals('test'));
      expect(rowSegs[0].tags, contains(LogTag.loggerName));

      expect(rowSegs[2].text, equals('info'));
      expect(rowSegs[2].tags, contains(LogTag.level));
    });

    test('Respects availableWidth by truncating row', () {
      const formatter = ToonFormatter(
        metadata: {}, // Only crucial content
      );
      const entryLong = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This is a very long message',
        timestamp: 'now',
        
      );

      // We use a width that allows breaking at the TAB.
      // info (4) + \t (4) = 8.
      const context = LogContext(availableWidth: 8);
      final lines = formatter.format(entryLong, context).toList();

      // The row line should have visibleLength 8
      final row =
          lines.firstWhere((final l) => l.toString().startsWith('info'));
      expect(row.visibleLength, equals(8));
      expect(row.toString(), equals('info\t'));
    });
  });
}
