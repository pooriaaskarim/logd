import 'dart:convert';
import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

class _CustomFormatter implements LogFormatter {
  const _CustomFormatter();

  @override
  Set<LogMetadata> get metadata => const {};

  @override
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    document.metadata[AutoEncoder.encoderKey] = const MarkdownEncoder();
    final node = factory.checkoutMessage()
      ..segments.add(const StyledText('Custom Formatter Message'));
    document.writeNode(node);
  }
}

void main() {
  group('Protocol Auto-Detect Encoders', () {
    const factory = StandardPipelineFactory();

    group('AutoConsoleEncoder', () {
      const encoder = AutoConsoleEncoder();

      test('auto-detects ToonFormatter metadata and uses ToonEncoder', () {
        const formatter = ToonFormatter();
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Hello TOON',
          loggerName: 'test',
          timestamp: '2026-08-01 10:00:00.000',
          origin: 'test.dart:10',
        );

        final document = formatDoc(formatter, entry);

        try {
          final context = HandlerContext();
          encoder
            ..preamble(
              context,
              LogLevel.info,
              factory,
              document: document,
            )
            ..encode(entry, document, LogLevel.info, context, factory);
          final output = const Utf8Decoder().convert(context.takeBytes());

          expect(
            output,
            contains(
              'logs[]{timestamp,logger,origin,level,message,error,stackTrace,'
              'context}:',
            ),
          );
          expect(output, contains('Hello TOON'));
        } finally {
          document.releaseRecursive(Arena.instance);
        }
      });

      test('auto-detects JsonFormatter metadata and uses JsonEncoder', () {
        const formatter = JsonFormatter();
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Hello JSON',
          loggerName: 'test',
          timestamp: '2026-08-01 10:00:00.000',
          origin: 'test.dart:10',
        );

        final document = formatDoc(formatter, entry);

        try {
          final context = HandlerContext();
          encoder.encode(entry, document, LogLevel.info, context, factory);
          final output = const Utf8Decoder().convert(context.takeBytes());

          final json = jsonDecode(output) as Map<String, dynamic>;
          expect(json['level'], equals('info'));
          expect(json['message'], equals('Hello JSON'));
        } finally {
          document.releaseRecursive(Arena.instance);
        }
      });

      test('auto-detects custom formatter encoder under AutoEncoder.encoderKey',
          () {
        const formatter = _CustomFormatter();
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Custom Message',
          loggerName: 'test',
          timestamp: '2026-08-01 10:00:00.000',
          origin: 'test.dart:10',
        );

        final document = formatDoc(formatter, entry);

        try {
          final context = HandlerContext();
          encoder.encode(entry, document, LogLevel.info, context, factory);
          final output = const Utf8Decoder().convert(context.takeBytes());

          // MarkdownEncoder renders bold text
          expect(output, contains('**Custom Formatter Message**'));
        } finally {
          document.releaseRecursive(Arena.instance);
        }
      });
    });

    group('AutoTextEncoder', () {
      const encoder = AutoTextEncoder();

      test('auto-detects ToonFormatter metadata for non-terminal sinks', () {
        const formatter = ToonFormatter();
        final entry = LogEntry(
          level: LogLevel.warning,
          message: 'Telemetry TOON',
          loggerName: 'audit',
          timestamp: '2026-08-01 10:00:00.000',
          origin: 'test.dart:10',
        );

        final document = formatDoc(formatter, entry);

        try {
          final context = HandlerContext();
          encoder
            ..preamble(
              context,
              LogLevel.warning,
              factory,
              document: document,
            )
            ..encode(entry, document, LogLevel.warning, context, factory);
          final output = const Utf8Decoder().convert(context.takeBytes());

          expect(
            output,
            contains(
              'logs[]{timestamp,logger,origin,level,message,error,stackTrace,'
              'context}:',
            ),
          );
          expect(output, contains('Telemetry TOON'));
        } finally {
          document.releaseRecursive(Arena.instance);
        }
      });

      test('falls back to PlainTextEncoder for standard StructuredFormatter',
          () {
        const formatter = PlainFormatter();
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Plain Text Log',
          loggerName: 'test',
          timestamp: '2026-08-01 10:00:00.000',
          origin: 'test.dart:10',
        );

        final document = formatDoc(formatter, entry);

        try {
          final context = HandlerContext();
          encoder.encode(entry, document, LogLevel.info, context, factory);
          final output = const Utf8Decoder().convert(context.takeBytes());

          expect(output, contains('Plain Text Log'));
          expect(output, isNot(contains('logs[]')));
        } finally {
          document.releaseRecursive(Arena.instance);
        }
      });
    });
  });
}
