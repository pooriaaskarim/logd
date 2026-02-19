import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';

void main() async {
  print('=== ToonFormatter Wrapping Check ===\n');

  // Scenario: Narrow width (40 chars)
  // Message is long enough to wrap.
  // TOON format expects single line per row (unless multiline is on).
  // If it wraps, it breaks the column structure.

  final handler = Handler(
    formatter: const ToonFormatter(),
    sink: ConsoleSink(),
    lineLength: 40,
  );

  Logger.configure('toon.test', handlers: [handler]);
  final logger = Logger.get('toon.test');

  print('--- Test Log ---');
  logger.info(
      'This is a very long message that is definitely longer than 40 characters and should ideally not wrap if we want to preserve TOON structure.');

  // Check manual "multiline" option
  final handlerMultiline = Handler(
    formatter: const ToonFormatter(multiline: true),
    sink: ConsoleSink(),
    lineLength: 40,
  );
  Logger.configure('toon.multiline', handlers: [handlerMultiline]);
  final loggerMulti = Logger.get('toon.multiline');

  print('\n--- Multiline Log ---');
  loggerMulti
      .info('Multiline on: This message is also very long and might wrap?');
}
