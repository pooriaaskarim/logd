// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:logd/src/handler/handler.dart';

import 'formatter_benchmark.dart';

class PipelineBenchmark extends BenchmarkBase {
  PipelineBenchmark() : super('FullPipeline');

  late LogEntry entry;
  late Handler handler;

  @override
  void setup() {
    entry = createEntry();
    handler = Handler(
      formatter: const PlainFormatter(),
      sink: RecordingSink(),
    );
  }

  @override
  void run() {
    handler.log(entry);
  }
}

base class RecordingSink extends LogSink<LogDocument> {
  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    // Release immediately to simulate memory pressure/cleanup
    document.releaseRecursive(factory);
  }
}

class ArenaPipelineBenchmark extends BenchmarkBase {
  ArenaPipelineBenchmark() : super('ArenaFullPipeline');

  late LogEntry entry;
  late Handler handler;

  @override
  void setup() {
    entry = createEntry();
    // Use an explicitly pooled configuration if possible,
    // but here we just test the default which uses Arena.
    handler = Handler(
      formatter: const PlainFormatter(),
      sink: RecordingSink(),
    );
  }

  @override
  void run() {
    handler.log(entry);
  }
}

class ManualPipelineBenchmark extends BenchmarkBase {
  ManualPipelineBenchmark() : super('ManualPipeline');

  late LogEntry entry;
  late LogFormatter formatter;
  late TerminalLayout layout;
  late LogEncoder encoder;

  @override
  void setup() {
    entry = createEntry();
    formatter = const PlainFormatter();
    layout =
        const TerminalLayout(width: 80, factory: StandardPipelineFactory());
    encoder = const PlainTextEncoder();
  }

  @override
  void run() {
    const factory = StandardPipelineFactory();
    final doc = factory.checkoutDocument();
    try {
      formatter.format(entry, doc, factory);
      final physical = layout.layout(doc, LogLevel.info);
      final context = HandlerContext();
      encoder.encode(entry, doc, LogLevel.info, context, factory);
      context.takeBytes();
      physical.releaseRecursive(factory);
    } finally {
      doc.releaseRecursive(factory);
    }
  }
}

void runPipelineBenchmarks() {
  print('\n--- Pipeline Throughput ---');
  PipelineBenchmark().report();
  ArenaPipelineBenchmark().report();
  ManualPipelineBenchmark().report();
}
