// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'dart:async';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';

class StandardEngineBenchmark extends BenchmarkBase {
  StandardEngineBenchmark() : super('StandardEngine (Sync JSON)');

  late Handler handler;
  late LogEntry entry;

  @override
  void setup() {
    handler = Handler(
      formatter: const JsonFormatter(),
      sink: EncodingSink(
        encoder: const JsonEncoder(),
        delegate: (final _) {},
      ),
      engine: const StandardEngine(),
    );

    entry = LogEntry(
      message: 'Benchmark payload for StandardEngine vs AsyncHandler',
      level: LogLevel.info,
      loggerName: 'bench.async',
      origin: 'async_benchmark.dart:25',
      timestamp: '2026-07-29T11:00:00Z',
    );
  }

  @override
  void run() {
    handler.log(entry);
  }
}

class AsyncHandlerBenchmark extends AsyncBenchmarkBase {
  AsyncHandlerBenchmark() : super('AsyncHandler (Isolate-offloaded JSON)');

  late AsyncHandler handler;
  late LogEntry entry;

  @override
  Future<void> setup() async {
    handler = AsyncHandler(
      formatter: const JsonFormatter(),
      sink: EncodingSink(
        encoder: const JsonEncoder(),
        delegate: (final _) {},
      ),
    );
    await handler.ready;

    entry = LogEntry(
      message: 'Benchmark payload for StandardEngine vs AsyncHandler',
      level: LogLevel.info,
      loggerName: 'bench.async',
      origin: 'async_benchmark.dart:55',
      timestamp: '2026-07-29T11:00:00Z',
    );
  }

  @override
  Future<void> run() async {
    await handler.log(entry);
  }

  @override
  Future<void> teardown() async {
    await handler.dispose();
  }
}

Future<void> runAsyncHandlerBenchmarks() async {
  print('\n--- AsyncHandler vs StandardEngine Performance ---');
  StandardEngineBenchmark().report();
  await AsyncHandlerBenchmark().report();
}
