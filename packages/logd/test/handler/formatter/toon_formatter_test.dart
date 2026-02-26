import 'dart:convert';
import 'dart:typed_data';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

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
      final doc = formatDoc(formatter, entry);
      try {
        final lines = renderToon(doc, entry, LogLevel.info);

        // Header includes: timestamp,logger,origin,level,message,error,
        // stackTrace
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
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('Respects custom metadata selection', () {
      const formatter = ToonFormatter(metadata: {LogMetadata.logger});
      final doc = formatDoc(formatter, entry);
      try {
        final lines = renderToon(doc, entry, LogLevel.info);

        expect(
          lines[0],
          equals('logs[]{logger,level,message,error,stackTrace}:'),
        );
        expect(lines[1], equals('test\tINFO\tmsg\t\t'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
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

      final doc = formatDoc(formatter, complexEntry);
      try {
        final lines = renderToon(doc, complexEntry, LogLevel.info);
        // INFO \t msg \t {a:1,b:[2,3]} \t
        expect(lines[1], contains('{a:1,b:[2,3]}'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
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

      final doc = formatDoc(formatter, complexEntry);
      try {
        final lines = renderToon(doc, complexEntry, LogLevel.info);
        expect(lines[1], contains('{a:2,z:1}'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
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

      final doc = formatDoc(formatter, complexEntry);
      try {
        final lines = renderToon(doc, complexEntry, LogLevel.info);
        expect(lines[1], contains('{a:...}'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });
}

List<String> renderToon(
  final LogDocument doc,
  final LogEntry entry,
  final LogLevel level,
) {
  const encoder = ToonEncoder();
  final context = HandlerContext();
  encoder.preamble(context, level, document: doc);
  final header = Uint8List.fromList(context.takeBytes());

  encoder.encode(entry, doc, level, context);
  final row = Uint8List.fromList(context.takeBytes());

  const decoder = Utf8Decoder();
  return [
    if (header.isNotEmpty) decoder.convert(header),
    decoder.convert(row),
  ];
}
