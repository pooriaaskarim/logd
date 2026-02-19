import 'formatter_benchmark.dart';
import 'decorator_benchmark.dart';
import 'pipeline_benchmark.dart';
import 'multi_sink_benchmark.dart';

void main() {
  print('Running Baseline Benchmarks...');
  print('==============================');

  runFormatterBenchmarks();
  runDecoratorBenchmarks();
  runPipelineBenchmarks();
  runMultiSinkBenchmarks();

  print('==============================');
  print('Benchmarks Complete.');
}
