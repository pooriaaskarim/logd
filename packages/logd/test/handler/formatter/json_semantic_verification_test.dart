import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  group('JsonPrettyFormatter Semantic Verification', () {
    test('deeply nested object has correct semantic structure', () {
      final data = {
        'level1': {
          'level2': {
            'level3': 'value',
            'list': [
              1,
              2,
              {'nested': true},
            ],
          },
        },
      };

      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test.dart',
        level: LogLevel.info,
        message: 'Complex JSON',
        timestamp: '2025-01-01',
        error: data, // Overriding error to test recursive formatting
      );

      const formatter = JsonPrettyFormatter(color: true);
      final doc = formatDoc(formatter, entry);
      try {
        // Verify structure via lines (end-to-end)
        const layout = TerminalLayout(width: 80);
        final lines = layout.layout(doc, LogLevel.info).lines;
        final output = lines.join('\n');

        expect(output, contains('  "level1": {'));
        expect(output, contains('    "level2": {'));
        expect(output, contains('      "level3": "value",'));
        expect(output, contains('      "list": ['));
        expect(output, contains('        1,'));
        expect(output, contains('        2,'));
        expect(output, contains('        {'));
        expect(output, contains('"nested":'));
        expect(output, contains('true'));

        // Verify tags on a specific line
        final keyLine =
            lines.firstWhere((final l) => l.toString().contains('"level1":'));
        expect(
          keyLine.segments.any((final s) => (s.tags & LogTag.key) != 0),
          isTrue,
        );
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('hanging indent for long values via DecoratedNode', () {
      const longText = 'This is a very long text that should wrap and maintain '
          'its indent relative to the key.';
      final data = {'longKey': longText};

      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test.dart',
        level: LogLevel.info,
        message: 'Wrap Test',
        timestamp: '2025-01-01',
        error: data,
      );

      // Use a narrow width to force wrapping
      const formatter = JsonPrettyFormatter();
      final doc = formatDoc(formatter, entry);
      try {
        // Use helper to simulate terminal
        const layout = TerminalLayout(width: 30);
        final lines = layout
            .layout(doc, LogLevel.info)
            .lines
            .map((final l) => l.toString())
            .toList();

        for (final line in lines) {
          if (line.contains('long text')) {
            // Continuation lines should be indented by '  "longKey": '.length
            // spaces
            expect(
              line.startsWith('           '),
              isTrue,
            );
          }
        }
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });
}
