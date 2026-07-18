import 'package:logd/logd.dart';
import 'formatter_benchmark.dart';
import 'decorator_benchmark.dart';
import 'pipeline_benchmark.dart';
import 'multi_sink_benchmark.dart';
import 'stress_test.dart';
import 'memory_churn_benchmark.dart';
import 'v080_native_offload.dart';
import 'invalidation_benchmark.dart';
import 'timezone_benchmark.dart';

Future<void> main() async {
  print('Running Baseline Benchmarks...');
  print('==============================');

  runFormatterBenchmarks();
  runDecoratorBenchmarks();
  await runPipelineBenchmarks();
  runMultiSinkBenchmarks();
  runInvalidationBenchmark();
  runTimezoneBenchmarks();

  await runNativeOffloadBenchmarks();

  // ignore: invalid_use_of_internal_member
  Arena.instance.clear();

  await runStressTests();
  await runMemoryChurnBenchmark();

  // ignore: invalid_use_of_internal_member
  Arena.instance.disposeNative();

  print('==============================');
  print('Benchmarks Complete.');
}
