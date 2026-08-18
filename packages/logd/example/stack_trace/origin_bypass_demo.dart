import 'dart:io';
import 'package:logd/logd.dart';
import 'package:logd/testing.dart';

void main() async {
  print('===============================================================');
  print('       logd Origin & Stack Trace Validation Demo');
  print('===============================================================\n');

  // 1. Comparison of output across formatters
  print('--- 1. Comparing Formatter Visual Outputs ---');

  Logger.configure(
    'demo.with_origin',
    includeOrigin: true,
    includeFileLineInHeader: true,
    handlers: [
      ConsoleHandler(
        formatter: const StructuredFormatter(),
      ),
    ],
  );

  Logger.configure(
    'demo.no_origin',
    includeOrigin: false,
    handlers: [
      ConsoleHandler(
        formatter: const StructuredFormatter(),
      ),
    ],
  );

  print('\n[With Origin Enabled (includeOrigin: true)]');
  Logger.get('demo.with_origin').info('User checked out shopping cart');

  print('\n[With Origin Bypassed (includeOrigin: false)]');
  Logger.get('demo.no_origin').info('User checked out shopping cart');

  // 2. Error and Stack Trace Handling
  print('\n--- 2. Error & Frame Collection with Origin Bypassed ---');

  Logger.configure(
    'demo.errors',
    includeOrigin: false,
    stackMethodCount: const {
      LogLevel.error: 3,
    },
    handlers: [
      ConsoleHandler(
        formatter: const PlainFormatter(),
      ),
    ],
  );

  try {
    throw const SocketException('Connection refused by host: 127.0.0.1:8080');
  } catch (e, st) {
    Logger.get('demo.errors').error(
      'Failed to reach database node',
      error: e,
      stackTrace: st,
    );
  }

  // 3. Hot-Path Latency Measurement (10,000 logs in-memory)
  print('\n--- 3. Hot-Path Latency Measurement (10,000 logs in-memory) ---');

  final memSink = CaptureSink();
  Logger.configure(
    'bench.with_origin',
    includeOrigin: true,
    handlers: [Handler(formatter: const PlainFormatter(), sink: memSink)],
  );
  Logger.configure(
    'bench.no_origin',
    includeOrigin: false,
    handlers: [Handler(formatter: const PlainFormatter(), sink: memSink)],
  );

  final withOriginLogger = Logger.get('bench.with_origin');
  final noOriginLogger = Logger.get('bench.no_origin');

  // Warmup
  for (var i = 0; i < 500; i++) {
    withOriginLogger.info('warmup');
    noOriginLogger.info('warmup');
  }
  memSink.clear();

  final swWith = Stopwatch()..start();
  for (var i = 0; i < 10000; i++) {
    withOriginLogger.info('benchmark');
  }
  swWith.stop();

  memSink.clear();

  final swWithout = Stopwatch()..start();
  for (var i = 0; i < 10000; i++) {
    noOriginLogger.info('benchmark');
  }
  swWithout.stop();

  final timeWith = swWith.elapsedMicroseconds / 10000;
  final timeWithout = swWithout.elapsedMicroseconds / 10000;

  print(
      'Average Dispatch Time (includeOrigin: true) : ${timeWith.toStringAsFixed(2)} µs/log');
  print(
      'Average Dispatch Time (includeOrigin: false): ${timeWithout.toStringAsFixed(2)} µs/log');
  print('Speedup: ${(timeWith / timeWithout).toStringAsFixed(2)}x faster\n');

  print('===============================================================');
  print('                     Validation Complete');
  print('===============================================================');
}
