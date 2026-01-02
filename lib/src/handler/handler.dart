library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:meta/meta.dart';

import '../core/context.dart';
import '../core/io/file_system.dart';
import '../core/utils.dart';
import '../logger/logger.dart';
import '../stack_trace/stack_trace.dart';
import '../time/timestamp.dart';

part 'decorator/ansi_color_decorator.dart';
part 'decorator/decorator.dart';
part 'filter/filter.dart';
part 'filter/level_filter.dart';
part 'filter/regex_filter.dart';
part 'formatter/box_formatter.dart';
part 'formatter/formatter.dart';
part 'formatter/json_formatter.dart';
part 'formatter/plain_formatter.dart';
part 'sink/console_sink.dart';
part 'sink/file_sink.dart';
part 'sink/multi_sink.dart';
part 'sink/network_sink.dart';
part 'sink/sink.dart';

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
  });

  /// The formatter used to transform a [LogEntry] into a sequence of lines.
  final LogFormatter formatter;

  /// The sink where the formatted and decorated lines are sent.
  final LogSink sink;

  /// A list of filters applied to each [LogEntry] before any processing.
  ///
  /// All filters must return `true` for the log entry to be processed.
  final List<LogFilter> filters;

  /// A list of decorators applied to the formatted lines in order.
  final List<LogDecorator> decorators;

  /// Process the entry: filter, format, decorate, output.
  Future<void> log(final LogEntry entry) async {
    if (filters.any((final filter) => !filter.shouldLog(entry))) {
      return;
    }
    var lines = formatter.format(entry);

    for (final decorator in decorators) {
      lines = decorator.decorate(lines, entry.level);
    }

    if (lines.isNotEmpty) {
      await sink.output(lines, entry.level);
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is Handler &&
          runtimeType == other.runtimeType &&
          formatter == other.formatter &&
          sink == other.sink &&
          listEquals(filters, other.filters) &&
          listEquals(decorators, other.decorators);

  @override
  int get hashCode =>
      formatter.hashCode ^
      sink.hashCode ^
      Object.hashAll(filters) ^
      Object.hashAll(decorators);
}
