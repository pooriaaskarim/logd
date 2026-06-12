import 'dart:async';
import 'dart:typed_data';
import 'package:logd/logd.dart';

Future<void> runNativeOffloadBenchmarks() async {
  print('\n--- Phase 1: Native Offload Scaling (10k iterations) ---');

  final sink = NativeIsolateSink(BlackholeEncodingSink());
  final handler = Handler(
    formatter: const PlainFormatter(),
    sink: sink,
    engine: const NativeEngine(),
  );

  // Warmup
  for (int i = 0; i < 1000; i++) {
    final warmupEntry = LogEntry(
      level: LogLevel.info,
      message: 'Warmup $i',
      loggerName: 'benchmark',
      origin: 'benchmark.dart',
      timestamp: DateTime.now().toIso8601String(),
    );
    // ignore: invalid_use_of_internal_member
    await handler.log(warmupEntry);
  }

  print('\n--- Phase 1: Native Offload Scaling (10k iterations) ---');
  final watch = Stopwatch()..start();

  for (int i = 0; i < 10000; i++) {
    final entry = LogEntry(
      level: LogLevel.info,
      message: 'Native offload $i',
      loggerName: 'benchmark',
      origin: 'benchmark.dart',
      timestamp: DateTime.now().toIso8601String(),
    );
    // ignore: invalid_use_of_internal_member
    await handler.log(entry);
    if (i % 1000 == 0) print('  Progress: $i/10000');
  }

  watch.stop();
  final totalUs = watch.elapsedMicroseconds;
  print(
      'NativeEngineOffload (Phase 1): ${(totalUs / 10000).toStringAsFixed(2)} us/op');

  await sink.dispose();
}

base class BlackholeEncodingSink extends EncodingSink {
  BlackholeEncodingSink()
      : super(encoder: const PlainTextEncoder(), delegate: _blackhole);
  static Future<void> _blackhole(Uint8List data) async {}
}
