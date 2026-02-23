// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'dart:io';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;

final entry = const LogEntry(
  loggerName: 'bench.logger.a.b.c',
  level: LogLevel.info,
  message:
      'This is a realistic benchmark log payload to test throughput limits.',
  timestamp: '2023-10-27T10:00:00.000Z',
  origin: 'benchmark.dart:42',
);

class Metrics {
  final double opsPerSec;
  final double p90, p95, p99;
  final int allocatedBytesPer10k;

  Metrics(
    this.opsPerSec,
    this.p90,
    this.p95,
    this.p99,
    this.allocatedBytesPer10k,
  );

  @override
  String toString() {
    return '${opsPerSec.toStringAsFixed(0)} Ops/sec | p90: ${p90.toStringAsFixed(2)}µs | '
        'p95: ${p95.toStringAsFixed(2)}µs | p99: ${p99.toStringAsFixed(2)}µs | '
        'GC Pressure: ${(allocatedBytesPer10k / 1024).toStringAsFixed(2)} KB/10k';
  }
}

Metrics profilePipeline(
  String name, {
  required LogFormatter formatter,
  List<LogDecorator> decorators = const [],
  int width = 80,
  int iterations = 10000, // Reduced for interactive speed, usually 50k
}) {
  print('Profiling: $name ...');

  final latencies = <int>[];
  final layout = TerminalLayout(width: width);

  // Warmup
  for (int i = 0; i < 1000; i++) {
    var doc = formatter.format(entry);
    for (final decorator in decorators) {
      doc = decorator.decorate(doc, entry);
    }
    final physical = layout.layout(doc, entry.level);
    for (final line in physical.lines) {
      line.toString();
    }
  }

  // Memory baseline
  final memStart = ProcessInfo.currentRss;

  // Timing
  final totalWatch = Stopwatch()..start();
  final iterWatch = Stopwatch();

  for (int i = 0; i < iterations; i++) {
    iterWatch.reset();
    iterWatch.start();

    var doc = formatter.format(entry);
    for (final decorator in decorators) {
      doc = decorator.decorate(doc, entry);
    }

    // Simulate physical layout and encoding
    final physical = layout.layout(doc, entry.level);
    for (final line in physical.lines) {
      line.toString();
    }

    iterWatch.stop();
    latencies.add(iterWatch.elapsedMicroseconds);
  }

  totalWatch.stop();
  final memEnd = ProcessInfo.currentRss;

  // Calculate ops/sec
  final double opsPerSec =
      iterations / (totalWatch.elapsedMicroseconds / 1000000);

  // Calculate Memory Pressure
  final int memDiff = memEnd > memStart ? memEnd - memStart : 0;
  final int bytesPer10k = (memDiff / iterations * 10000).toInt();

  // Calculate Tail Latency (p90, p95, p99)
  latencies.sort();
  final p90 = latencies[(iterations * 0.90).toInt()].toDouble();
  final p95 = latencies[(iterations * 0.95).toInt()].toDouble();
  final p99 = latencies[(iterations * 0.99).toInt()].toDouble();

  return Metrics(opsPerSec, p90, p95, p99, bytesPer10k);
}

void main() {
  print('# Logd Handler Pipeline - Stress Test & Profiling');
  print('**Dart:** ${Platform.version}');
  print(
      '**OS:** ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n');

  print('### 1. The Raw Machine (JSON -> FileSink)');
  final machine = profilePipeline(
    'Raw Machine',
    formatter: const JsonFormatter(),
  );
  print(machine);
  print('');

  print('### 2. The Modern Human (Structured -> Box -> ConsoleSink)');
  final human = profilePipeline(
    'Modern Human',
    formatter: const StructuredFormatter(),
    decorators: const [BoxDecorator()],
  );
  print(human);
  print('');

  print('### 3. The Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width)');
  final squeeze = profilePipeline(
    'Framing Squeeze',
    formatter: const StructuredFormatter(),
    decorators: const [
      HierarchyDepthPrefixDecorator(),
      BoxDecorator(),
    ],
    width: 40,
  );
  print(squeeze);
  print('');
}
