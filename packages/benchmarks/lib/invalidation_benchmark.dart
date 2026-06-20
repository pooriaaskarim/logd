// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';

class InvalidationBenchmark extends BenchmarkBase {
  InvalidationBenchmark()
      : super('Descendant Invalidation (10,000 Unrelated, 1 Descendant)');

  @override
  void setup() {
    Logger.configure('global', enabled: true);
    // Configure 1 child under parent
    Logger.get('parent.child0').enabled;
    // Configure and populate cache for 10000 unrelated loggers
    for (var i = 0; i < 10000; i++) {
      Logger.get('unrelated.logger$i').enabled;
    }
  }

  @override
  void run() {
    // Invalidate the parent
    Logger.configure('parent', logLevel: LogLevel.warning);
    // Re-resolve the single child
    Logger.get('parent.child0').enabled;
  }
}

void runInvalidationBenchmark() {
  print('\n--- Cache Invalidation Performance ---');
  InvalidationBenchmark().report();
}
