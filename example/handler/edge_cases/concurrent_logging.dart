// Example: Concurrent Logging
//
// Demonstrates:
// - Multiple loggers writing simultaneously
// - Thread safety
// - No interleaving of log entries
// - File sink concurrent writes
//
// Expected: Clean, non-interleaved output

import 'dart:async';
import 'package:logd/logd.dart';

void main() async {
  final handler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
        lineLength: 80,
        useColors: false,
      ),
    ],
    sink: FileSink('logs/concurrent.log'),
  );

  Logger.configure('example.concurrent', handlers: [handler]);

  // Create multiple loggers
  final loggers = List.generate(
    5,
    (i) => Logger.get('example.concurrent.worker$i'),
  );

  // Log concurrently
  final futures = <Future>[];
  for (int i = 0; i < loggers.length; i++) {
    final logger = loggers[i];
    for (int j = 0; j < 10; j++) {
      futures.add(
        Future(() async {
          logger.info('Worker $i, message $j');
        }),
      );
    }
  }

  await Future.wait(futures);

  print('Check logs/concurrent.log');
  print('Verify that log entries are not interleaved');
}
