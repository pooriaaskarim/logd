import 'dart:async';
// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'formatter_benchmark.dart';

// No-op sink for benchmarking
final class NullSink extends LogSink<LogDocument> {
  const NullSink();

  @override
  Future<void> output(final LogDocument document, final LogEntry entry,
      final LogLevel level) async {
    // Consume nodes to force evaluation if lazy (nodes are List, so mostly instant)
    for (final _ in document.nodes) {}
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

    final arena = LogArena.instance;
    final doc = arena.checkoutDocument();

    try {
      handler.formatter.format(entry, doc, arena);

      // Decorate
      for (final decorator in handler.decorators) {
        decorator.decorate(doc, entry, arena);
      }

      if (doc.nodes.isNotEmpty) {
        // Consume
        for (final _ in doc.nodes) {}
      }
    } finally {
      doc.releaseRecursive(arena);
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

class JsonPrettyPipelineBenchmark extends PipelineBenchmark {
  JsonPrettyPipelineBenchmark() : super('JsonPretty Pipeline');

  @override
  Handler createHandler() {
    return const Handler(
      formatter: JsonPrettyFormatter(),
      sink: NullSink(),
    );
  }
}

class MarkdownPipelineBenchmark extends PipelineBenchmark {
  MarkdownPipelineBenchmark() : super('Markdown Pipeline');

  @override
  Handler createHandler() {
    return const Handler(
      formatter: MarkdownFormatter(),
      sink: NullSink(),
    );
  }
}

void runPipelineBenchmarks() {
  print('\n--- E2E Pipeline Overhead ---');
  SimplePipelineBenchmark().report();
  ComplexPipelineBenchmark().report();
  JsonPrettyPipelineBenchmark().report();
  MarkdownPipelineBenchmark().report();
}
