import 'dart:async';
import 'dart:typed_data';
import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart';
import 'package:logd/src/logger/logger.dart';

Future<void> runNativeOffloadBenchmarks() async {
  print('\n--- Phase 1: Native Offload Scaling (10k iterations) ---');
  
  final entry = const LogEntry(
    loggerName: 'bench.native',
    level: LogLevel.info,
    message: 'Testing native isolate offload latency.',
    origin: 'benchmark.dart:42',
    timestamp: '2023-10-27T10:00:00.000Z',
  );

  final sink = NativeIsolateSink(BlackholeEncodingSink());
  final handler = Handler(
    formatter: const PlainFormatter(),
    sink: sink,
    engine: const NativeEngine(),
  );

  // Warmup
  for (int i = 0; i < 1000; i++) {
    await handler.log(entry);
  }

  final watch = Stopwatch()..start();
  final int iterations = 2000;
  
  for (int i = 0; i < iterations; i++) {
    await handler.log(entry);
  }
  
  watch.stop();
  final totalUs = watch.elapsedMicroseconds;
  final avgUs = totalUs / iterations;
  
  print('NativeEngineOffload (Phase 1): ${avgUs.toStringAsFixed(2)} us/op');

  await sink.dispose();
}

base class BlackholeEncodingSink extends EncodingSink {
  BlackholeEncodingSink() : super(encoder: const PlainTextEncoder(), delegate: _blackhole);
  static Future<void> _blackhole(Uint8List data) async {}
}
