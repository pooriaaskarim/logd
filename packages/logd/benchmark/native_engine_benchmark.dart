import 'dart:async';
import 'dart:typed_data';
import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart';
import 'package:logd/src/logger/logger.dart';

/// Performance benchmark comparing StandardEngine vs. NativeEngine (Binary-IR).
void main() async {
  print('--- logd Performance Benchmark ---');
  print('Testing 10,000 logs with complex layout...\n');

  final entry = LogEntry(
    level: LogLevel.info,
    message: 'Performance Benchmark Test Message',
    loggerName: 'benchmark',
    origin: 'main',
    timestamp: DateTime.now().toString(),
  );

  final formatter = ToonFormatter();
  
  // We use EncodingSink with a null delegate to test the pipeline speed.
  final sink = EncodingSink(
    encoder: AnsiEncoder(),
    delegate: (data) {},
  );

  // 1. Benchmark StandardEngine
  final standardHandler = Handler(
    formatter: formatter,
    sink: sink,
    engine: const StandardEngine(),
  );
  
  // Warm up
  for (int i = 0; i < 100; i++) await standardHandler.log(entry);

  final standardSw = Stopwatch()..start();
  for (int i = 0; i < 10000; i++) {
    await standardHandler.log(entry);
  }
  standardSw.stop();
  
  // 2. Benchmark NativeEngine (Fast-Path)
  final nativeHandler = Handler(
    formatter: formatter,
    sink: sink,
    engine: const NativeEngine(),
  );
  
  // Warm up
  for (int i = 0; i < 100; i++) await nativeHandler.log(entry);

  final nativeSw = Stopwatch()..start();
  for (int i = 0; i < 10000; i++) {
    await nativeHandler.log(entry);
  }
  nativeSw.stop();

  // 3. Results
  print('StandardEngine: ${standardSw.elapsedMilliseconds}ms (${(10000 / (standardSw.elapsedMilliseconds / 1000)).toStringAsFixed(2)} logs/sec)');
  print('NativeEngine (B-IR): ${nativeSw.elapsedMilliseconds}ms (${(10000 / (nativeSw.elapsedMilliseconds / 1000)).toStringAsFixed(2)} logs/sec)');
  
  final improvement = ((standardSw.elapsedMilliseconds - nativeSw.elapsedMilliseconds) / standardSw.elapsedMilliseconds * 100).toStringAsFixed(2);
  print('\nPerformance Improvement: $improvement%');
}
