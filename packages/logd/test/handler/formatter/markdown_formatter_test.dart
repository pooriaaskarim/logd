import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownFormatter', () {
    const formatter = MarkdownFormatter(metadata: {});

    test('structures basic log entry with level emoji', () {
      const entry = LogEntry(
        level: LogLevel.info,
        message: 'Hello Markdown',
        loggerName: 'test',
        timestamp: '2023-10-27T10:00:00.000Z',
        origin: 'test.dart:42',
      );

      final document = formatter.format(
        entry,
        LogArena.instance,
      );

      expect(document.nodes, hasLength(2));
      expect(document.nodes[0], isA<HeaderNode>());
      expect(document.nodes[1], isA<MessageNode>());

      const encoder = MarkdownEncoder();
      final output = encoder.encode(entry, document, LogLevel.info);

      expect(output, contains('### ℹ️ INFO'));
      expect(output, contains('**Hello Markdown**'));
    });

    test('structures error and stack trace with collapsible tags', () {
      final entry = LogEntry(
        level: LogLevel.error,
        message: 'Fatal Error',
        loggerName: 'test',
        timestamp: '2023-10-27T10:00:00.000Z',
        origin: 'test.dart:42',
        error: 'System failure',
        stackTrace: StackTrace.fromString('line 1\nline 2'),
      );

      final document = formatter.format(
        entry,
        LogArena.instance,
      );

      expect(document.nodes, hasLength(4));
      expect(document.nodes[2], isA<ErrorNode>());
      expect(document.nodes[3], isA<FooterNode>());
      expect((document.nodes[3].tags & LogTag.collapsible) != 0, isTrue);

      const encoder = MarkdownEncoder();
      final output = encoder.encode(entry, document, LogLevel.error);

      expect(output, contains('### ❌ ERROR'));
      expect(output, contains('> [!ERROR]'));
      expect(output, contains('<details>'));
      expect(output, contains('<summary>Stack Trace</summary>'));
      expect(output, contains('```'));
      expect(output, contains('line 1'));
    });
  });
}
