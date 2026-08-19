import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'pipeline_benchmark.dart';

class WithoutContextBenchmark extends BenchmarkBase {
  WithoutContextBenchmark() : super('Logger.info (no context)');

  late Logger logger;

  @override
  void setup() {
    Logger.reset();
    Logger.configure(
      'bench.no_context',
      includeOrigin: false,
      handlers: const [
        Handler(
          formatter: PlainFormatter(),
          sink: RecordingSink(),
          engine: ArenaEngine(),
        ),
      ],
    );
    logger = Logger.get('bench.no_context');
  }

  @override
  void run() {
    logger.info('Standard benchmark message');
  }
}

class WithAmbientContextBenchmark extends BenchmarkBase {
  WithAmbientContextBenchmark() : super('Logger.info (ambient LogContext)');

  late Logger logger;

  @override
  void setup() {
    Logger.reset();
    Logger.configure(
      'bench.ambient_context',
      includeOrigin: false,
      handlers: const [
        Handler(
          formatter: PlainFormatter(),
          sink: RecordingSink(),
          engine: ArenaEngine(),
        ),
      ],
    );
    logger = Logger.get('bench.ambient_context');
  }

  @override
  void run() {
    LogContext.run(const {'requestId': 'req-12345', 'userId': 42}, () {
      logger.info('Ambient context benchmark message');
    });
  }
}

void runLogContextBenchmarks() {
  print('--- Ambient LogContext (MDC) Throughput ---');
  WithoutContextBenchmark().report();
  WithAmbientContextBenchmark().report();
}
