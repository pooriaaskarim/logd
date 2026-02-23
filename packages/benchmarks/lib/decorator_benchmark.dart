// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'formatter_benchmark.dart'; // reutilize createEntry/context

abstract class DecoratorBenchmark extends BenchmarkBase {
  DecoratorBenchmark(super.name);

  late LogEntry entry;
  late LogFormatter formatter;
  late LogDecorator decorator;
  late List<String> baseLines;

  @override
  void setup() {
    entry = createEntry();
    formatter = const PlainFormatter();
    final layout = const TerminalLayout(width: 80);
    baseLines = layout
        .layout(formatter.format(entry), LogLevel.info)
        .lines
        .map((final l) => l.toString())
        .toList(); // Pre-calculate base
    decorator = createDecorator();
  }

  LogDecorator createDecorator();

  @override
  void run() {
    final nodes = baseLines
        .map((final l) => MessageNode(segments: [StyledText(l)]))
        .toList();
    final document = LogDocument(nodes: nodes);
    final decorated = decorator.decorate(document, entry);

    final layout = const TerminalLayout(width: 80);
    final lines = layout.layout(decorated, LogLevel.info).lines;
    for (final _ in lines) {}
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

class SuffixDecoratorBenchmark extends DecoratorBenchmark {
  SuffixDecoratorBenchmark() : super('SuffixDecorator');

  @override
  LogDecorator createDecorator() => const SuffixDecorator(' | SUFFIX');
}

class HierarchyDepthPrefixDecoratorBenchmark extends DecoratorBenchmark {
  HierarchyDepthPrefixDecoratorBenchmark()
      : super('HierarchyDepthPrefixDecorator');

  @override
  LogDecorator createDecorator() => const HierarchyDepthPrefixDecorator();
}

void runDecoratorBenchmarks() {
  print('\n--- Decorator Overhead ---');
  BoxDecoratorBenchmark().report();
  PrefixDecoratorBenchmark().report();
  StyleDecoratorBenchmark().report();
  SuffixDecoratorBenchmark().report();
  HierarchyDepthPrefixDecoratorBenchmark().report();
}
