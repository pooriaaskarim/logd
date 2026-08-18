import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'pipeline_benchmark.dart';

class WithOriginLoggerBenchmark extends BenchmarkBase {
  WithOriginLoggerBenchmark() : super('Logger.info(includeOrigin: true)');

  late Logger logger;

  @override
  void setup() {
    Logger.reset();
    Logger.configure(
      'bench.origin',
      includeOrigin: true,
      handlers: const [
        Handler(
          formatter: PlainFormatter(),
          sink: RecordingSink(),
          engine: ArenaEngine(),
        ),
      ],
    );
    logger = Logger.get('bench.origin');
  }

  @override
  void run() {
    logger.info('Benchmark message');
  }
}

class WithoutOriginLoggerBenchmark extends BenchmarkBase {
  WithoutOriginLoggerBenchmark() : super('Logger.info(includeOrigin: false)');

  late Logger logger;

  @override
  void setup() {
    Logger.reset();
    Logger.configure(
      'bench.no_origin',
      includeOrigin: false,
      handlers: const [
        Handler(
          formatter: PlainFormatter(),
          sink: RecordingSink(),
          engine: ArenaEngine(),
        ),
      ],
    );
    logger = Logger.get('bench.no_origin');
  }

  @override
  void run() {
    logger.info('Benchmark message');
  }
}

void runLazyStackBenchmarks() {
  print('--- Lazy Stack & Origin Bypass Throughput ---');
  WithOriginLoggerBenchmark().report();
  WithoutOriginLoggerBenchmark().report();
}
