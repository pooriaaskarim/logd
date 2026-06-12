import 'dart:convert';

import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('JsonFormatter', () {
    final entry = LogEntry(
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
        doc.releaseRecursive(Arena.instance);
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
        doc.releaseRecursive(Arena.instance);
      }
    });
  });

  group('JsonPrettyFormatter', () {
    final entry = LogEntry(
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
        expect(output, contains('  "message": '));
        expect(output, contains('  '));
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });

    test('emits SectionNode for nested objects', () {
      const formatter = JsonPrettyFormatter();
      final errorMap = {
        'id': 123,
        'nested': {'deep': true},
      };
      final entryWithError = LogEntry(
        level: LogLevel.info,
        message: 'msg',
        loggerName: 'test',
        origin: 'test.dart:1',
        timestamp: '2026-03-22',
        error: errorMap,
      );
      final doc = formatDoc(formatter, entryWithError);
      try {
        // Find the SectionNode for the root error object or nested object
        final sections = <SectionNode>[];
        void collect(final LogNode node) {
          if (node is SectionNode) {
            sections.add(node);
          }
          if (node is LayoutNode) {
            node.children.forEach(collect);
          }
        }

        doc.nodes.forEach(collect);

        expect(sections.length, greaterThanOrEqualTo(1));
        final idSection = sections.firstWhere(
          (final s) => s.summary.toString().contains('id'),
        );
        expect(idSection.tags & LogTag.collapsible, isNot(0));

        // Check summary contains opening bracket and preview
        final summaryText = idSection.summary.toString();
        expect(summaryText, contains('{'));
        expect(summaryText, contains('id')); // Preview of first key

        // Verify LogTag.preview is present on the summary's segments
        final previewSegment = (idSection.summary as ContentNode)
            .segments
            .firstWhere((final s) => (s.tags & LogTag.preview) != 0);
        expect(previewSegment, isNotNull);
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });

    test('handles embedded JSON strings recursively', () {
      const formatter = JsonPrettyFormatter();
      final input = {
        'outer': '{"inner": {"deep": true, "more": "data", "even": "more", '
            '"trigger": "stacking"}}',
      };
      final entryWithNested = LogEntry(
        level: LogLevel.info,
        message: 'nested',
        loggerName: 'test',
        origin: 'test.dart:1',
        timestamp: '2026-03-22',
        error: input,
      );

      final doc = formatDoc(formatter, entryWithNested);
      try {
        final sections = <SectionNode>[];
        void collect(final LogNode node) {
          if (node is SectionNode) {
            sections.add(node);
          }
          if (node is LayoutNode) {
            node.children.forEach(collect);
          }
        }

        doc.nodes.forEach(collect);

        // The 'outer' string should have been parsed and wrapped in a
        // SectionNode
        final innerSection = sections.firstWhere(
          (final s) => s.summary.toString().contains('inner'),
        );
        expect(innerSection, isNotNull);
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });

    test('respects recursion depth', () {
      const formatter = JsonPrettyFormatter(maxDepth: 5);
      Object? deep = {'leaf': true};
      for (var i = 0; i < 10; i++) {
        deep = {'level_$i': deep};
      }

      final entryDeep = LogEntry(
        level: LogLevel.info,
        message: 'deep',
        loggerName: 'test',
        origin: 'test.dart:1',
        timestamp: '2026-03-22',
        error: deep,
      );

      final doc = formatDoc(formatter, entryDeep);
      try {
        expect(doc.nodes, isNotEmpty);
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });
  });

  group('JsonFormatter metadata selection', () {
    final entry = LogEntry(
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
        doc.releaseRecursive(Arena.instance);
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
        doc.releaseRecursive(Arena.instance);
      }
    });
  });

  group('JsonFormatter wrapping', () {
    final entry = LogEntry(
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
            const TerminalLayout(width: 80, factory: StandardPipelineFactory())
                .layout(doc, LogLevel.info)
                .lines;
        final segment = lines.first.segments.first;
        expect((segment.tags & LogTag.noWrap) == 0, isTrue);
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });
  });
}

List<String> render(final LogDocument doc) {
  // Use large width to prevent wrapping of JSON output
  final layout = TerminalLayout(width: 4096, factory: Arena.instance);
  return layout
      .layout(doc, LogLevel.info)
      .lines
      .map((final l) => l.toString())
      .toList();
}
