import 'dart:convert';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  group('MarkdownEncoder', () {
    const encoder = MarkdownEncoder();
    const factory = StandardPipelineFactory();

    test('renders StructuredFormatter IR with GFM elements', () {
      const formatter = StructuredFormatter(
        metadata: {LogMetadata.logger, LogMetadata.timestamp},
      );
      const entry = LogEntry(
        level: LogLevel.info,
        message: 'Hello Markdown',
        loggerName: 'test',
        timestamp: '2023-10-27T10:00:00.000Z',
        origin: 'test.dart:42',
      );

      final document = formatDoc(formatter, entry);

      try {
        final context = HandlerContext();
        encoder.encode(entry, document, LogLevel.info, context, factory);
        final output = const Utf8Decoder().convert(context.takeBytes());

        // StructuredFormatter now has joined headers: Timestamp • [INFO] [test]
        expect(output, contains('### ℹ️ 2023-10-27T10:00:00.000Z • [INFO] [test]'));
        expect(output, contains('**Hello Markdown**'));
        expect(output, contains('---'));
      } finally {
        document.releaseRecursive(Arena.instance);
      }
    });

    test('renders Error and StackTrace in GFM blocks', () {
      const formatter = StructuredFormatter(metadata: {});
      final entry = LogEntry(
        level: LogLevel.error,
        message: 'Fatal Error',
        loggerName: 'test',
        timestamp: '2023-10-27T10:00:00.000Z',
        origin: 'test.dart:42',
        error: 'System failure',
        stackTrace: StackTrace.fromString('line 1\nline 2'),
      );

      final document = formatDoc(formatter, entry);
      try {
        final context = HandlerContext();
        encoder.encode(entry, document, LogLevel.error, context, factory);
        final output = const Utf8Decoder().convert(context.takeBytes());

        expect(output, contains('### ❌ [ERROR]'));
        expect(output, contains('> [!ERROR]'));
        expect(output, contains('**Fatal Error**'));
        expect(output, contains('line 1'));
      } finally {
        document.releaseRecursive(Arena.instance);
      }
    });

    test('renders JsonFormatter map as a code block', () {
      const formatter = JsonFormatter(metadata: {});
      const entry = LogEntry(
        level: LogLevel.info,
        message: 'JSON Event',
        loggerName: 'test',
        timestamp: '2023-10-27T10:00:00.000Z',
        origin: 'test.dart:42',
      );

      final document = formatDoc(formatter, entry);
      try {
        final context = HandlerContext();
        encoder.encode(entry, document, LogLevel.info, context, factory);
        final output = const Utf8Decoder().convert(context.takeBytes());

        expect(output, contains('```json'));
        expect(output, contains('"level":"info"'));
        expect(output, contains('"message":"JSON Event"'));
        expect(output, contains('```'));
      } finally {
        document.releaseRecursive(Arena.instance);
      }
    });
  });
}
