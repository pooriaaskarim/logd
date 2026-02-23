// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';

// Helper to create a dummy LogEntry
LogEntry createEntry() {
  return const LogEntry(
    level: LogLevel.info,
    message: 'This is a benchmark log message with typical length.',
    loggerName: 'benchmark.logger',
    timestamp: '2023-10-27T10:00:00.000Z',
    origin: 'benchmark.dart:42',
  );
}

abstract class FormatterBenchmark extends BenchmarkBase {
  FormatterBenchmark(super.name);

  late LogEntry entry;
  late LogFormatter formatter;

  @override
  void setup() {
    entry = createEntry();
    formatter = createFormatter();
  }

  LogFormatter createFormatter();

  @override
  void run() {
    final context = const LogContext(availableWidth: 80);
    final lines = formatter.format(entry, context);
    for (final _ in lines) {}
  }
}

class PlainFormatterBenchmark extends FormatterBenchmark {
  PlainFormatterBenchmark() : super('PlainFormatter');

  @override
  LogFormatter createFormatter() => const PlainFormatter();
}

class StructuredFormatterBenchmark extends FormatterBenchmark {
  StructuredFormatterBenchmark() : super('StructuredFormatter');

  @override
  LogFormatter createFormatter() => const StructuredFormatter();
}

class ToonFormatterBenchmark extends FormatterBenchmark {
  ToonFormatterBenchmark() : super('ToonFormatter');

  @override
  LogFormatter createFormatter() => const ToonFormatter();
}

class JsonFormatterBenchmark extends FormatterBenchmark {
  JsonFormatterBenchmark() : super('JsonFormatter');

  @override
  LogFormatter createFormatter() => const JsonFormatter();
}

void runFormatterBenchmarks() {
  print('\n--- Formatter Throughput ---');
  PlainFormatterBenchmark().report();
  StructuredFormatterBenchmark().report();
  ToonFormatterBenchmark().report();
  JsonFormatterBenchmark().report();
}
