/// The orchestration layer for the Logd pipeline.
///
/// This library defines the [Handler] and the core models for processing
/// logs. It uses a structured [LogDocument] as the intermediate representation.
///
library;

import 'dart:async';

import 'package:meta/meta.dart';

import '../core/utils/utils.dart';
import '../logger/logger.dart';
import 'decorator/decorator.dart';
import 'document/document.dart';
import 'engine/engine.dart';
import 'filter/filter.dart';
import 'formatter/formatter.dart';
import 'sink/sink.dart';

export 'decorator/decorator.dart';
export 'document/document.dart';
export 'encoder/encoder.dart';
export 'engine/engine.dart';
export 'filter/filter.dart';
export 'formatter/formatter.dart';
export 'layout/layout.dart';
export 'sink/sink.dart';

/// Composes a [LogFormatter], a [LogSink], and optional filters and decorators.
///
/// The [Handler] is the central orchestration unit in the logging pipeline. It
/// filters incoming [LogEntry]s, transforms them using a [LogFormatter],
/// applies a sequence of [LogDecorator]s, and finally sends the results to a
/// [LogSink].
@immutable
class Handler {
  /// Creates a [Handler].
  const Handler({
    required this.formatter,
    required this.sink,
    this.filters = const [],
    this.decorators = const [],
    this.engine = const StandardEngine(),
    this.timeout,
  });

  /// The formatter used to transform a [LogEntry] into a [LogDocument].
  final LogFormatter formatter;

  /// The sink where the formatted and decorated lines are sent.
  final LogSink sink;

  /// A list of filters applied to each [LogEntry] before any processing.
  ///
  /// All filters must return `true` for the log entry to be processed.
  final List<LogFilter> filters;

  /// The execution strategy for the log pipeline.
  final LogEngine engine;

  /// A list of decorators applied to the [LogDocument] in order.
  final List<LogDecorator> decorators;

  /// The maximum duration allowed for processing a log entry.
  final Duration? timeout;

  /// Process the entry: filter, format, decorate, output.
  @internal
  Future<void> log(final LogEntry entry) async {
    if (filters.any((final filter) => !filter.shouldLog(entry))) {
      return;
    }

    if (timeout != null) {
      await engine
          .execute(entry, formatter, decorators, sink)
          .timeout(timeout!);
    } else {
      await engine.execute(entry, formatter, decorators, sink);
    }
  }

  /// Disposes of any resources held by this handler.
  ///
  /// Subclasses that manage stateful resources (such as background isolates
  /// or file handles) should override this method to clean up resources.
  @mustCallSuper
  Future<void> dispose() async {}

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is Handler &&
          runtimeType == other.runtimeType &&
          formatter == other.formatter &&
          sink == other.sink &&
          engine == other.engine &&
          timeout == other.timeout &&
          listEquals(filters, other.filters) &&
          listEquals(decorators, other.decorators);

  @override
  int get hashCode =>
      formatter.hashCode ^
      sink.hashCode ^
      engine.hashCode ^
      timeout.hashCode ^
      Object.hashAll(filters) ^
      Object.hashAll(decorators);
}
