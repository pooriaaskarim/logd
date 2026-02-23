// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'formatter_benchmark.dart';
import 'pipeline_benchmark.dart'; // Reuse NullSink

class MultiSinkBenchmark extends BenchmarkBase {
  final int sinkCount;
  MultiSinkBenchmark(this.sinkCount) : super('MultiSink (x$sinkCount)');

  late LogEntry entry;
  late Handler handler;

  @override
  void setup() {
    entry = createEntry();

    final sinks = List.generate(sinkCount, (_) => const NullSink());

    handler = Handler(
      formatter: const StructuredFormatter(),
      sink: MultiSink(sinks),
    );
  }

  @override
  void run() {
    _manualPipelineRun();
  }

  void _manualPipelineRun() {
    // ... setup context ...

    final document = handler.formatter.format(entry);

    // Simulate MultiSink behavior
    for (var i = 0; i < sinkCount; i++) {
      // Just consume nodes, mimicking output()
      for (final _ in document.nodes) {}
    }
  }
}

void runMultiSinkBenchmarks() {
  print('\n--- Multi-Sink Scaling ---');
  // 1 Sink
  MultiSinkBenchmark(1).report();
  // 2 Sinks - should show ~2x cost in Master if lazy re-eval happens
  MultiSinkBenchmark(2).report();
  // 4 Sinks - should show ~4x cost in Master
  MultiSinkBenchmark(4).report();
}
