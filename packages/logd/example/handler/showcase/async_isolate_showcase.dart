import 'dart:async';
import 'dart:io';
import 'package:logd/logd.dart';

/// A custom sink that simulates a slow console/file rendering or physical write delay
/// by blocking the active executing thread for 1000ms.
base class SlowConsoleSink extends LogSink<LogDocument> {
  const SlowConsoleSink();

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    // Synchronously block the active thread for 1 second
    sleep(const Duration(seconds: 1));

    // Render document to stdout using the PlainTextEncoder
    final context = factory.checkoutContext();
    const PlainTextEncoder().encode(
      entry,
      document,
      level,
      context,
      factory,
    );
    final data = context.takeBytes();
    stdout.add(data);
  }
}

void main() async {
  print('\x1B[1m\x1B[96mlogd\x1B[0m | Isolate Logging & Concurrency Showcase');
  print(
      '\x1B[2m─────────────────────────────────────────────────────────────\x1B[0m');

  print('\x1B[1m=== DEMO 1: Synchronous Logging (Thread Blocking) ===\x1B[0m');
  print(
      'Logging a message with a 1-second write delay directly on the main thread...');

  final syncHandler = Handler(
    formatter: const PlainFormatter(
      metadata: {
        LogMetadata.timestamp,
        LogMetadata.logger,
      },
    ),
    decorators: const [
      StyleDecorator(),
      BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: const SlowConsoleSink(),
  );

  Logger.configure('sys.sync', handlers: [syncHandler]);
  final syncLogger = Logger.get('sys.sync');

  final syncStopwatch = Stopwatch()..start();

  // Log message (blocks main thread for 1 second)
  syncLogger.info('Slow synchronous log.');

  print(
      '👉 [Main Thread] Logging call finished. Simulating 1.5s task execution...');
  for (int i = 1; i <= 10; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    print('  └─ Main Thread: performing active computation step $i/10 '
        '(Elapsed: ${syncStopwatch.elapsedMilliseconds}ms)');
  }

  print(
      '\x1B[2m─────────────────────────────────────────────────────────────\x1B[0m\n');
  await Future<void>.delayed(const Duration(milliseconds: 500));

  print(
      '\x1B[1m=== DEMO 2: Isolate-Backed Logging (Concurrent/Non-Blocking) ===\x1B[0m');
  print('Logging the same message offloaded to a background isolate worker...');

  final asyncHandler = AsyncHandler(
    formatter: const PlainFormatter(
      metadata: {
        LogMetadata.timestamp,
        LogMetadata.logger,
      },
    ),
    decorators: const [
      StyleDecorator(),
      BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: const SlowConsoleSink(),
  );

  Logger.configure('sys.async', handlers: [asyncHandler]);
  final asyncLogger = Logger.get('sys.async');

  final asyncStopwatch = Stopwatch()..start();

  // Log message (offloaded to background isolate, returns instantly)
  asyncLogger.info('Slow asynchronous log.');

  print(
      '👉 [Main Thread] Logging call finished. Simulating 1.5s task execution...');
  for (int i = 1; i <= 10; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    print('  └─ Main Thread: performing active computation step $i/10 '
        '(Elapsed: ${asyncStopwatch.elapsedMilliseconds}ms)');
  }

  // Give the background isolate a moment to finish printing if needed
  await Future<void>.delayed(const Duration(milliseconds: 500));

  await asyncHandler.dispose();

  print('\n\x1B[1m\x1B[92m[Observation Guide]\x1B[0m');
  print(
      '* In Demo 1: The main thread was completely frozen for 1 second. The log box '
      'printed first, and then the computation steps started printing late.');
  print(
      '* In Demo 2: The computation steps started printing IMMEDIATELY in real-time. '
      'The log box printed by the background isolate popped up in the MIDDLE of active progress, '
      'demonstrating true asynchronous execution.');
}
