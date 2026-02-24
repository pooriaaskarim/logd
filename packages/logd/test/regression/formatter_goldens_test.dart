import 'dart:convert';
import 'dart:io';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';
import '../utils/log_snap.dart';

void main() {
  group('Formatter Goldens (Baseline)', () {
    const entry = LogEntry(
      loggerName: 'SnapTest',
      origin: 'snap.dart:10:5',
      level: LogLevel.info,
      message: 'This is a standard log message for golden verification.',
      timestamp: '2025-01-01 12:00:00',
    );

    const longEntry = LogEntry(
      loggerName: 'LongSnap',
      origin: 'long.dart',
      level: LogLevel.warning,
      message: 'A very long message that should trigger wrapping across '
          'multiple lines to verify structural integrity and spacing.',
      timestamp: '2025-01-01 12:00:01',
    );

    final formatters = {
      'Plain': const PlainFormatter(),
      'Structured': const StructuredFormatter(),
      'Toon': const ToonFormatter(),
    };

    final widths = [80, 40, 20];

    for (final entryName in ['Standard', 'Long']) {
      final currentEntry = entryName == 'Standard' ? entry : longEntry;

      group('Entry: $entryName', () {
        for (final entry in formatters.entries) {
          final formatterName = entry.key;
          final formatter = entry.value;

          group('Formatter: $formatterName', () {
            for (final width in widths) {
              test('Width: $width', () {
                final doc = formatter.format(
                  currentEntry,
                  LogArena.instance,
                );

                final output = LogSnap.capture(
                  doc,
                  currentEntry.level,
                  width: width,
                  useAnsi: false, // Plain text for goldens to avoid escape code
                  // noise
                );

                // Detect package root to avoid pollution when run from
                // workspace root
                final baseDir = File('lib/logd.dart').existsSync()
                    ? 'test/regression/goldens'
                    : 'packages/logd/test/regression/goldens';

                final fileName =
                    '${formatterName.toLowerCase()}_${entryName.toLowerCase()}'
                    '_$width.txt';
                final file =
                    File('$baseDir/${formatterName.toLowerCase()}/$fileName');

                if (!file.existsSync()) {
                  file.parent
                      .createSync(recursive: true); // Ensure directory exists
                  file.writeAsStringSync(output);
                  print('Generated golden: ${file.path}');
                } else {
                  final expected = file.readAsStringSync();
                  expect(
                    output,
                    expected,
                    reason: 'Output mismatch for $formatterName | $entryName | '
                        '$width. '
                        'If this is an intentional change, delete the golden'
                        ' file and re-run.',
                  );
                }
              });
            }
          });
        }
      });
    }
  });

  group('Html Goldens (Baseline)', () {
    const entry = LogEntry(
      loggerName: 'HtmlTest',
      origin: 'html.dart:5:1',
      level: LogLevel.info,
      message: 'Html golden message for regression.',
      timestamp: '2025-01-01 12:00:00',
    );

    const errorEntry = LogEntry(
      loggerName: 'HtmlTest',
      origin: 'html.dart:10:1',
      level: LogLevel.error,
      message: 'An error occurred during processing.',
      timestamp: '2025-01-01 12:00:05',
    );

    const encoder = HtmlEncoder(darkMode: true);

    final htmlFormatters = {
      'plain': const PlainFormatter(),
      'structured': const StructuredFormatter(),
      'toon': const ToonFormatter(),
    };

    for (final testEntry in {'standard': entry, 'error': errorEntry}.entries) {
      final entryName = testEntry.key;
      final currentEntry = testEntry.value;

      for (final fEntry in htmlFormatters.entries) {
        final formatterName = fEntry.key;
        final formatter = fEntry.value;

        test('HtmlEncoder $formatterName $entryName', () {
          final doc = formatter.format(currentEntry, LogArena.instance);
          final context = HandlerContext();
          encoder.encode(currentEntry, doc, currentEntry.level, context);
          final html = const Utf8Decoder().convert(context.takeBytes());

          // Detect package root
          final baseDir = File('lib/logd.dart').existsSync()
              ? 'test/regression/goldens'
              : 'packages/logd/test/regression/goldens';

          final fileName = 'html_${formatterName}_$entryName.html';
          final file = File('$baseDir/html/$fileName');

          if (!file.existsSync()) {
            file.parent.createSync(recursive: true);
            file.writeAsStringSync(html);
            print('Generated HTML golden: ${file.path}');
          } else {
            final expected = file.readAsStringSync();
            expect(
              html,
              expected,
              reason: 'HTML output mismatch for $formatterName | $entryName. '
                  'If intentional, delete the golden file and re-run.',
            );
          }
        });
      }
    }
  });
}
