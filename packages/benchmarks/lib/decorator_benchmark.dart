// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'formatter_benchmark.dart'; // reutilize createEntry/context

abstract class DecoratorBenchmark extends BenchmarkBase {
  DecoratorBenchmark(super.name);

  late LogEntry entry;
  late LogFormatter formatter;
  late LogDecorator decorator;
  late List<LogLine> baseLines;

  @override
  void setup() {
    entry = createEntry();
    formatter = const PlainFormatter();
    final context = const LogContext(availableWidth: 80);
    baseLines = formatter.format(entry, context).toList(); // Pre-calculate base
    decorator = createDecorator();
  }

  LogDecorator createDecorator();

  @override
  void run() {
    final context = const LogContext(availableWidth: 80);
    final decorated = decorator.decorate(baseLines, entry, context);
    for (final _ in decorated) {}
  }
}

class BoxDecoratorBenchmark extends DecoratorBenchmark {
  BoxDecoratorBenchmark() : super('BoxDecorator');

  @override
  LogDecorator createDecorator() => const BoxDecorator();
}

class PrefixDecoratorBenchmark extends DecoratorBenchmark {
  PrefixDecoratorBenchmark() : super('PrefixDecorator');

  @override
  LogDecorator createDecorator() => const PrefixDecorator('PREFIX | ');
}

class StyleDecoratorBenchmark extends DecoratorBenchmark {
  StyleDecoratorBenchmark() : super('StyleDecorator');

  @override
  LogDecorator createDecorator() => const StyleDecorator();
}

void runDecoratorBenchmarks() {
  print('\n--- Decorator Overhead ---');
  BoxDecoratorBenchmark().report();
  PrefixDecoratorBenchmark().report();
  StyleDecoratorBenchmark().report();
}
