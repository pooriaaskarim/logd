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
                  LogContext(availableWidth: width),
                );

                final output = LogSnap.capture(
                  doc,
                  currentEntry.level,
                  width: width,
                  useAnsi:
                      false, // Plain text for goldens to avoid escape code noise
                );

                final fileName =
                    '${formatterName.toLowerCase()}_${entryName.toLowerCase()}_${width}.txt';
                final file = File(
                    'test/regression/goldens/${formatterName.toLowerCase()}/$fileName');

                if (!file.existsSync()) {
                  file.parent
                      .createSync(recursive: true); // Ensure directory exists
                  file.writeAsStringSync(output);
                  print('Generated golden: ${file.path}');
                } else {
                  final expected = file.readAsStringSync();
                  expect(output, expected,
                      reason:
                          'Output mismatch for $formatterName | $entryName | $width. '
                          'If this is an intentional change, delete the golden file and re-run.');
                }
              });
            }
          });
        }
      });
    }
  });
}
