import 'package:logd/logd.dart';
import 'package:logd/src/stack_trace/stack_trace.dart';
import 'package:test/test.dart';

import '../decorator/mock_context.dart';

void main() {
  group('MarkdownFormatter', () {
    const entry = LogEntry(
      loggerName: 'test.logger',
      origin: 'main.dart:10:5',
      level: LogLevel.error,
      message: 'Critical failure detected',
      timestamp: '2025-01-01 10:00:00',
    );

    test('formats identity header with default profound style', () {
      const formatter = MarkdownFormatter();
      final lines = formatter.format(entry, mockContext).toList();

      expect(
        lines[0].toString(),
        contains('### ❌ ERROR | test.logger | 2025-01-01 10:00:00'),
      );
      expect(lines[1].toString(), contains('*Origin: main.dart:10:5*'));
    });

    test('respects headingLevel configuration', () {
      const formatter = MarkdownFormatter(headingLevel: 1);
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines[0].toString(), startsWith('# ❌ ERROR'));
    });

    test('respects LogMetadata selection', () {
      const formatter = MarkdownFormatter(
        metadata: {LogMetadata.logger}, // No timestamp, no origin
      );
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines[0].toString(), contains('ERROR | test.logger'));
      expect(lines[0].toString(), isNot(contains('| 2025-01-01')));
      expect(lines.any((final l) => l.toString().contains('Origin')), isFalse);
    });

    test('formats message as blockquote', () {
      const formatter = MarkdownFormatter();
      final lines = formatter.format(entry, mockContext).toList();

      expect(
        lines.any((final l) => l.toString() == '> Critical failure detected'),
        isTrue,
      );
    });

    test('handles multiline messages beautifully', () {
      const multilineEntry = LogEntry(
        loggerName: 'test.logger',
        origin: 'main.dart:10:5',
        level: LogLevel.error,
        message: 'Line 1\nLine 2',
        timestamp: '2025-01-01 10:00:00',
      );
      const formatter = MarkdownFormatter();
      final lines = formatter.format(multilineEntry, mockContext).toList();

      expect(lines.any((final l) => l.toString() == '> Line 1'), isTrue);
      expect(lines.any((final l) => l.toString() == '> Line 2'), isTrue);
    });

    test('formats collapsible stack traces', () {
      const entryWithStack = LogEntry(
        loggerName: 'test.logger',
        origin: 'main.dart:10:5',
        level: LogLevel.error,
        message: 'Stack Test',
        timestamp: '2025-01-01 10:00:00',
        stackFrames: [
          CallbackInfo(
            className: '',
            methodName: 'main',
            fullMethod: 'main',
            filePath: 'main.dart',
            lineNumber: 10,
          ),
        ],
      );
      const formatter = MarkdownFormatter();
      final lines = formatter
          .format(entryWithStack, mockContext)
          .map((final l) => l.toString())
          .toList();

      expect(lines, contains('<details>'));
      expect(lines, contains('<summary>Stack Trace</summary>'));
      expect(lines, contains('at main (main.dart:10)'));
      expect(lines, contains('</details>'));
    });

    test('formats errors as bold blockquotes', () {
      const errorEntry = LogEntry(
        loggerName: 'test.logger',
        origin: 'main.dart:10:5',
        level: LogLevel.error,
        message: 'Msg',
        timestamp: '2025-01-01',
        error: 'Serious Error',
      );
      const formatter = MarkdownFormatter();
      final lines = formatter
          .format(errorEntry, mockContext)
          .map((final l) => l.toString())
          .toList();
      expect(lines, contains('> **Error:** Serious Error'));
    });
  });
}
