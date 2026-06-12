// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart';

import 'formatter_benchmark.dart';

class PipelineBenchmark extends AsyncBenchmarkBase {
  PipelineBenchmark() : super('FullPipeline');

  late LogEntry entry;
  late Handler handler;

  @override
  Future<void> setup() async {
    entry = createEntry();
    handler = const Handler(
      formatter: PlainFormatter(),
      sink: RecordingSink(),
      engine: StandardEngine(),
    );
  }

  @override
  Future<void> run() async {
    await handler.log(entry);
  }
}

base class RecordingSink extends LogSink<LogDocument> {
  const RecordingSink();

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    // Evaluates nodes to simulate a real sink, but does NOT release.
    // The engine handles the lifecycle.
    for (final _ in document.nodes) {}
  }
}

class ArenaPipelineBenchmark extends AsyncBenchmarkBase {
  ArenaPipelineBenchmark() : super('ArenaFullPipeline');

  late LogEntry entry;
  late Handler handler;

  @override
  Future<void> setup() async {
    entry = createEntry();
    handler = const Handler(
      formatter: PlainFormatter(),
      sink: RecordingSink(),
      engine: ArenaEngine(),
    );
  }

  @override
  Future<void> run() async {
    await handler.log(entry);
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
    final factory = Arena.instance;
    final doc = factory.checkoutDocument();
    try {
      formatter.format(entry, doc, factory);
      final physical = layout.layout(doc, LogLevel.info);
      final context = factory.checkoutContext();
      encoder.encode(entry, doc, LogLevel.info, context, factory);
      context.takeBytes();
      physical.releaseRecursive(factory);
    } finally {
      doc.releaseRecursive(factory);
    }
  }
}

Future<void> runPipelineBenchmarks() async {
  print('\n--- Pipeline Throughput ---');
  await PipelineBenchmark().report();
  await ArenaPipelineBenchmark().report();
  ManualPipelineBenchmark().report();
}
