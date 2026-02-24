import 'formatter_benchmark.dart';
import 'decorator_benchmark.dart';
import 'pipeline_benchmark.dart';
import 'multi_sink_benchmark.dart';
import 'stress_test.dart';
import 'memory_churn_benchmark.dart';

Future<void> main() async {
  print('Running Baseline Benchmarks...');
  print('==============================');

  runFormatterBenchmarks();
  runDecoratorBenchmarks();
  runPipelineBenchmarks();
  runMultiSinkBenchmarks();

  runStressTests();
  await runMemoryChurnBenchmark();

  print('==============================');
  print('Benchmarks Complete.');
}
