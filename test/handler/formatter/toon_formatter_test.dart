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

      final structure = formatter.format(entry, mockContext);
      final lines = renderLines(structure);

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
      final structure = formatter.format(entry, mockContext);
      final lines = renderLines(structure);

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
      final structure = formatter.format(entry, mockContext);
      final lines = structure.nodes.map((final b) => b as ContentNode).toList();

      // Row is index 1
      final row = lines[1];
      final rowSegs = row.segments;

      // Delimiter \t is at index 1
      expect(rowSegs[0].text, equals('test'));
      expect(rowSegs[0].tags, contains(LogTag.loggerName));

      expect(rowSegs[2].text, equals('info'));
      expect(rowSegs[2].tags, contains(LogTag.level));
    });

    test('Respects availableWidth via AnsiEncoder', () {
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

      // info (4) + \t (1 cell visible) = 5.
      // Message starts after delimiter.
      final structure =
          formatter.format(entryLong, const LogContext(availableWidth: 10));

      const encoder = AnsiEncoder();
      // We pass the width in metadata for the encoder
      final rendered = encoder
          .encode(structure.copyWith(metadata: {'width': 10}), LogLevel.info)
          .split('\n');

      final row = rendered.firstWhere((final l) => l.startsWith('info'));
      // visibleLength should be around 10.
      expect(LogLine.text(row).visibleLength, lessThanOrEqualTo(10));
    });
  });
}
