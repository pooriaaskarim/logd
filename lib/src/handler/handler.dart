library;

import 'dart:convert';
import 'dart:io' as io;

import '../logger/logger.dart';
import '../stack_trace/stack_trace.dart';

part 'filter/filter.dart';
part 'filter/level_filter.dart';
part 'filter/regex_filter.dart';
part 'formatter/formatter.dart';
part 'formatter/box_formatter.dart';
part 'formatter/json_formatter.dart';
part 'sink/sink.dart';
part 'sink/multi_sink.dart';
part 'sink/network_sink.dart';
part 'sink/file_sink.dart';
part 'sink/console_sink.dart';

/// Composes a [LogFormatter] and [LogSink] with optional filters.
class Handler {
  const Handler({
    required this.formatter,
    required this.sink,
    this.filters = const [],
  });

  /// The formatter to transform the entry into lines.
  final LogFormatter formatter;

  /// The sink to output the formatted lines.
  final LogSink sink;

  /// List of filters to apply before formatting (all must pass).
  final List<LogFilter> filters;

  /// Process the entry: filter, format, output.
  void log(final LogEntry entry) {
    if (filters.any((final filter) => !filter.shouldLog(entry))) {
      return;
    }
    final lines = formatter.format(entry);
    if (lines.isNotEmpty) {
      sink.output(lines, entry.level);
    }
  }
}
