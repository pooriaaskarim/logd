// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;

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
    // Consume the iterable to force execution
    final layout = const TerminalLayout(width: 80);
    final lines = layout.layout(formatter.format(entry), LogLevel.info).lines;
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

class JsonPrettyFormatterBenchmark extends FormatterBenchmark {
  JsonPrettyFormatterBenchmark() : super('JsonPrettyFormatter');

  @override
  LogFormatter createFormatter() => const JsonPrettyFormatter();
}

class MarkdownFormatterBenchmark extends FormatterBenchmark {
  MarkdownFormatterBenchmark() : super('MarkdownFormatter');

  @override
  LogFormatter createFormatter() => const MarkdownFormatter();
}

void runFormatterBenchmarks() {
  print('\n--- Formatter Throughput ---');
  PlainFormatterBenchmark().report();
  StructuredFormatterBenchmark().report();
  ToonFormatterBenchmark().report();
  JsonFormatterBenchmark().report();
  JsonPrettyFormatterBenchmark().report();
  MarkdownFormatterBenchmark().report();
}
