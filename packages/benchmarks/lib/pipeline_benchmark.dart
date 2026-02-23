import 'dart:async';
// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'formatter_benchmark.dart';

// No-op sink for benchmarking
final class NullSink extends LogSink {
  const NullSink();

  @override
  int get preferredWidth => 80;

  @override
  Future<void> output(
      final Iterable<LogLine> lines, final LogLevel level) async {
    // Consume lines
    for (final _ in lines) {}
  }
}

// Handler benchmark
abstract class PipelineBenchmark extends BenchmarkBase {
  PipelineBenchmark(super.name);

  late LogEntry entry;
  late Handler handler;

  @override
  void setup() {
    entry = createEntry();
    handler = createHandler();
  }

  Handler createHandler();

  @override
  void run() {
    _manualPipelineRun();
  }

  void _manualPipelineRun() {
    final filters = handler.filters;
    if (filters.any((f) => !f.shouldLog(entry))) return;

    final formatter = handler.formatter;
    final decorators = handler.decorators;
    final context = const LogContext(availableWidth: 80);

    var lines = formatter.format(entry, context);

    // Decorate
    for (final decorator in decorators) {
      lines = decorator.decorate(lines, entry, context);
    }

    if (lines.isNotEmpty) {
      // Consume
      for (final _ in lines) {}
    }
  }
}

class SimplePipelineBenchmark extends PipelineBenchmark {
  SimplePipelineBenchmark() : super('Simple Pipeline (Plain)');

  @override
  Handler createHandler() {
    return const Handler(
      formatter: PlainFormatter(),
      sink: NullSink(),
    );
  }
}

class ComplexPipelineBenchmark extends PipelineBenchmark {
  ComplexPipelineBenchmark() : super('Complex Pipeline (Structure+Box+Style)');

  @override
  Handler createHandler() {
    return const Handler(
      formatter: StructuredFormatter(),
      sink: NullSink(),
      decorators: [
        BoxDecorator(),
        StyleDecorator(),
        PrefixDecorator('APP | '),
      ],
    );
  }
}

void runPipelineBenchmarks() {
  print('\n--- E2E Pipeline Overhead ---');
  SimplePipelineBenchmark().report();
  ComplexPipelineBenchmark().report();
}
