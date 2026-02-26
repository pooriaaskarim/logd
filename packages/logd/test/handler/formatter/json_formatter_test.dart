import 'dart:convert';

import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  group('JsonFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'main.dart:10',
      level: LogLevel.info,
      message: 'Test message',
      timestamp: '2025-01-01 10:00:00',
    );

    test('outputs compact JSON with default metadata', () {
      const formatter = JsonFormatter();
      final doc = formatDoc(formatter, entry);
      try {
        final lines = render(doc);

        expect(lines.length, equals(1));
        final json = lines.first;
        final decoded = jsonDecode(json) as Map<String, dynamic>;

        // Metadata
        expect(decoded['timestamp'], equals('2025-01-01 10:00:00'));
        expect(decoded['logger'], equals('test'));
        expect(decoded['origin'], equals('main.dart:10'));

        // Crucial content
        expect(decoded['level'], equals('info'));
        expect(decoded['message'], equals('Test message'));

        expect(decoded['error'], isNull);
        expect(decoded['stackTrace'], isNull);
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('includes error when present regardless of metadata', () {
      final errorEntry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart:20',
        level: LogLevel.error,
        message: 'Failed',
        timestamp: '2025-01-01 10:00:00',
        error: 'Connection failed',
        stackTrace: StackTrace.fromString('stack line 1\n  stack line 2'),
      );

      const formatter = JsonFormatter(metadata: {});
      final doc = formatDoc(formatter, errorEntry);
      try {
        final lines = render(doc);

        expect(lines.length, equals(1));
        final json = lines.first;
        final decoded = jsonDecode(json) as Map<String, dynamic>;

        // Crucial content always present
        expect(decoded['level'], equals('error'));
        expect(decoded['message'], equals('Failed'));
        expect(decoded['error'], equals('Connection failed'));
        expect(decoded['stackTrace'], equals('stack line 1\n  stack line 2'));

        // Metadata omitted
        expect(decoded.containsKey('timestamp'), isFalse);
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });

  group('JsonPrettyFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'main.dart:10',
      level: LogLevel.info,
      message: 'Test message',
      timestamp: '2025-01-01 10:00:00',
    );

    test('outputs formatted JSON with indentation', () {
      const formatter = JsonPrettyFormatter();
      final doc = formatDoc(formatter, entry);
      try {
        final lines = render(doc);

        expect(lines.length, greaterThan(1));
        final output = lines.map((final l) => l).join('\n');

        expect(output, contains('  "timestamp": '));
        expect(output, contains('  "level": '));
        expect(output, contains('  "logger": '));
        expect(output, contains('  "message": '));
        expect(output, contains('  '));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });

  group('JsonSemanticFormatter tags', () {
    const entry = LogEntry(
      loggerName: 'app',
      origin: 'main.dart:10',
      level: LogLevel.info,
      message: 'Test message',
      timestamp: '2025-01-01 10:00:00',
    );

    test('emits semantic tags when color is true', () {
      const formatter = JsonPrettyFormatter(color: true);
      final doc = formatDoc(formatter, entry);
      try {
        final lines =
            const TerminalLayout(width: 80).layout(doc, LogLevel.info).lines;

        expect(lines.length, greaterThan(0));
        bool foundKey = false;
        bool foundLevel = false;
        bool foundPunctuation = false;
        for (final line in lines) {
          for (final segment in line.segments) {
            if ((segment.tags & LogTag.key) != 0) {
              foundKey = true;
            }
            if ((segment.tags & LogTag.level) != 0) {
              foundLevel = true;
            }
            if ((segment.tags & LogTag.punctuation) != 0) {
              foundPunctuation = true;
            }
          }
        }
        expect(foundKey, isTrue);
        expect(foundLevel, isTrue);
        expect(foundPunctuation, isTrue);
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });

  group('JsonFormatter metadata selection', () {
    const entry = LogEntry(
      loggerName: 'app.service',
      origin: 'service.dart:42',
      level: LogLevel.info,
      message: 'Processing request',
      timestamp: '2025-01-01 14:30:15.123',
    );

    test('includes only specified metadata but always crucial content', () {
      const formatter = JsonFormatter(
        metadata: {LogMetadata.timestamp},
      );
      final doc = formatDoc(formatter, entry);
      try {
        final lines = render(doc);

        final json = lines.first;
        final decoded = jsonDecode(json) as Map<String, dynamic>;

        // Metadata specified
        expect(decoded['timestamp'], equals('2025-01-01 14:30:15.123'));

        // Crucial content always there
        expect(decoded['level'], equals('info'));
        expect(decoded['message'], equals('Processing request'));

        // Other metadata omitted
        expect(decoded.containsKey('logger'), isFalse);
        expect(decoded.containsKey('origin'), isFalse);
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('empty metadata list still includes level and message', () {
      const formatter = JsonFormatter(metadata: {});
      final doc = formatDoc(formatter, entry);
      try {
        final lines = render(doc);

        final json = lines.first;
        final decoded = jsonDecode(json) as Map<String, dynamic>;

        expect(decoded['level'], equals('info'));
        expect(decoded['message'], equals('Processing request'));
        expect(decoded.length, equals(2));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });

  group('JsonFormatter wrapping', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'main.dart:10',
      level: LogLevel.info,
      message: 'Test message',
      timestamp: '2025-01-01 10:00:00',
    );

    test('default does not use noWrap tag', () {
      const formatter = JsonFormatter();
      final doc = formatDoc(formatter, entry);
      try {
        final lines =
            const TerminalLayout(width: 80).layout(doc, LogLevel.info).lines;
        final segment = lines.first.segments.first;
        expect((segment.tags & LogTag.noWrap) == 0, isTrue);
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });
}

List<String> render(final LogDocument doc) {
  // Use large width to prevent wrapping of JSON output
  const layout = TerminalLayout(width: 4096);
  return layout
      .layout(doc, LogLevel.info)
      .lines
      .map((final l) => l.toString())
      .toList();
}
