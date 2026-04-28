import 'package:flutter_test/flutter_test.dart';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';

void main() {
  group('TOON Schema Maturity', () {
    test('ToonFormatter produces legacy header by default', () async {
      const formatter = ToonFormatter(
        metadata: {LogMetadata.timestamp},
      );
      const entry = LogEntry(
        loggerName: 'test',
        level: LogLevel.info,
        message: 'hello',
        timestamp: '2026-04-28',
        origin: 'main',
      );
      final doc = LogDocument();
      formatter.format(entry, doc, const StandardPipelineFactory());

      const encoder = ToonEncoder();
      final context = HandlerContext();
      encoder.preamble(
        context,
        LogLevel.info,
        const StandardPipelineFactory(),
        document: doc,
      );

      expect(
        context.toString(),
        contains('logs[]{timestamp,level,message,error,stackTrace}:'),
      );
    });

    test('ToonFormatter produces explicit schema when requested', () async {
      const formatter = ToonFormatter(
        metadata: {LogMetadata.timestamp},
        explicitSchema: true,
      );
      const entry = LogEntry(
        loggerName: 'test',
        level: LogLevel.info,
        message: 'hello',
        timestamp: '2026-04-28',
        origin: 'main',
      );
      final doc = LogDocument();
      formatter.format(entry, doc, const StandardPipelineFactory());

      const encoder = ToonEncoder();
      final context = HandlerContext();
      encoder.preamble(
        context,
        LogLevel.info,
        const StandardPipelineFactory(),
        document: doc,
      );

      final output = context.toString();
      expect(output, contains('logs[]{'));
      expect(output, contains('  timestamp: iso8601;'));
      expect(output, contains('  level: enum;'));
      expect(output, contains('  message: markdown;'));
      expect(output, contains('}:'));
    });

    test('ToonPrettyFormatter produces explicit schema when requested',
        () async {
      const formatter = ToonPrettyFormatter(
        metadata: {LogMetadata.logger},
        explicitSchema: true,
      );
      const entry = LogEntry(
        loggerName: 'test',
        level: LogLevel.debug,
        message: 'pretty',
        timestamp: '2026-04-28',
        origin: 'main',
      );
      final doc = LogDocument();
      formatter.format(entry, doc, const StandardPipelineFactory());

      const encoder = ToonEncoder();
      final context = HandlerContext();
      encoder.preamble(
        context,
        LogLevel.debug,
        const StandardPipelineFactory(),
        document: doc,
      );

      final output = context.toString();
      expect(output, contains('logs[]{'));
      expect(output, contains('  logger: string;'));
      expect(output, contains('  level: enum;'));
      expect(output, contains('}:'));
    });
  });
}
