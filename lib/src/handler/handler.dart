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
import 'ansi_colors.dart';

part 'decorator/ansi_color_decorator.dart';
part 'decorator/box_decorator.dart';
part 'decorator/decorator.dart';
part 'decorator/hierarchy_depth_prefix_decorator.dart';
part 'decorator/prefix_decorator.dart';
part 'filter/filter.dart';
part 'filter/level_filter.dart';
part 'filter/regex_filter.dart';
part 'formatter/box_formatter.dart';
part 'formatter/formatter.dart';
part 'formatter/json_formatter.dart';
part 'formatter/plain_formatter.dart';
part 'formatter/structured_formatter.dart';
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
    Iterable<LogLine> lines = formatter.format(entry);

    /// Auto-sort to ensure correct visual composition:
    /// 1. TransformDecorator (Content mutation)
    /// 2. VisualDecorator (Content styling, e.g. ANSI colors)
    /// 3. StructuralDecorator (Outer wrapping, e.g. Box, then Indentation)
    ///
    /// Using a Set for deduplication to prevent redundant decorators.
    final sortedDecorators = decorators.toSet().toList()
      ..sort((final a, final b) {
        int priority(final LogDecorator decorator) {
          if (decorator is TransformDecorator) {
            return 0;
          }
          if (decorator is VisualDecorator) {
            return 1;
          }
          if (decorator is StructuralDecorator) {
            // Within Structural, Box comes before Hierarchy (Indentation).
            // Box wraps content, Hierarchy indents the wrapped box.
            if (decorator is BoxDecorator) {
              return 2;
            }
            if (decorator is HierarchyDepthPrefixDecorator) {
              return 3;
            }
            return 4; // Unknown structural decorators last
          }
          return 5; // Unknown other decorators
        }

        return priority(a).compareTo(priority(b));
      });

    for (final decorator in sortedDecorators) {
      lines = decorator.decorate(lines, entry);
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

/// Represents a single line in a log output, annotated with semantic tags.
@immutable
class LogLine {
  /// Creates a [LogLine].
  const LogLine(this.text, {this.tags = const {}});

  /// Creates a [LogLine] from a string without any tags.
  factory LogLine.plain(final String text) => LogLine(text);

  /// The textual content of the line.
  final String text;

  /// Semantic tags describing the content of the line.
  final Set<LogLineTag> tags;

  /// The visible width of the line, excluding ANSI escape sequences.
  int get visibleLength => text.visibleLength;

  @override
  String toString() => text;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogLine &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          _setEquals(tags, other.tags);

  @override
  int get hashCode => text.hashCode ^ Object.hashAll(tags);

  bool _setEquals<T>(final Set<T> a, final Set<T> b) {
    if (a.length != b.length) {
      return false;
    }
    return a.containsAll(b);
  }
}

// LogLineTag stays here
enum LogLineTag {
  /// General metadata like timestamp, level, or logger name.
  header,

  /// Information about where the log was emitted (file, line, function).
  origin,

  /// The primary log message body.
  message,

  /// Error information (exception message).
  error,

  /// Individual frame in a stack trace.
  stackFrame,

  /// Structural lines like box borders or dividers.
  border,

  /// Indicates the line already contains ANSI color/style codes.
  ansiColored,

  /// Indicates the line is already enclosed in a box.
  boxed,
}
