library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:meta/meta.dart';

import '../core/context/context.dart';
import '../core/context/io/file_system.dart';
import '../core/theme/ansi_adapter.dart';
import '../core/theme/log_theme.dart';
import '../core/utils/utils.dart';
import '../logger/logger.dart';
import '../stack_trace/stack_trace.dart';
import '../time/timestamp.dart';

part 'decorator/box_decorator.dart';
part 'decorator/decorator.dart';
part 'decorator/hierarchy_depth_prefix_decorator.dart';
part 'decorator/prefix_decorator.dart';
part 'decorator/style_decorator.dart';
part 'filter/filter.dart';
part 'filter/level_filter.dart';
part 'filter/regex_filter.dart';
part 'formatter/box_formatter.dart';
part 'formatter/formatter.dart';
part 'formatter/html_formatter.dart';
part 'formatter/json_formatter.dart';
part 'formatter/log_field.dart';
part 'formatter/markdown_formatter.dart';
part 'formatter/plain_formatter.dart';
part 'formatter/structured_formatter.dart';
part 'formatter/toon_formatter.dart';
part 'sink/console_sink.dart';
part 'sink/file_sink.dart';
part 'sink/html_sink.dart';
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
    this.lineLength,
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

  /// The maximum line length for the output.
  ///
  /// If provided, this overrides [LogSink.preferredWidth].
  final int? lineLength;

  /// Process the entry: filter, format, decorate, output.
  Future<void> log(final LogEntry entry) async {
    if (filters.any((final filter) => !filter.shouldLog(entry))) {
      return;
    }

    /// Context for the pipeline, merging handler config and sink capabilities.
    final context = LogContext(
      availableWidth: lineLength ?? sink.preferredWidth,
    );

    Iterable<LogLine> lines = formatter.format(entry, context);

    /// Auto-sort to ensure correct visual composition:
    /// 1. TransformDecorator (Content mutation)
    /// 2. StructuralDecorator (Outer wrapping, e.g. Box, then Indentation)
    /// 3. VisualDecorator (Content styling, e.g. AnsiColors)
    ///
    /// Using a Set for deduplication to prevent redundant decorators.
    final sortedDecorators = decorators.toSet().toList()
      ..sort((final a, final b) {
        int priority(final LogDecorator decorator) {
          if (decorator is TransformDecorator) {
            return 0;
          }
          if (decorator is StructuralDecorator) {
            // Within Structural, Box comes before Hierarchy (Indentation).
            // Box wraps content, Hierarchy indents the wrapped box.
            if (decorator is BoxDecorator) {
              return 1;
            }
            if (decorator is HierarchyDepthPrefixDecorator) {
              return 2;
            }
            return 3; // Unknown structural decorators
          }
          if (decorator is VisualDecorator) {
            return 4;
          }
          return 5; // Unknown other decorators
        }

        return priority(a).compareTo(priority(b));
      });

    for (final decorator in sortedDecorators) {
      lines = decorator.decorate(lines, entry, context);
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

/// Shared context passed through the logging pipeline.
///
/// The [LogContext] acts as the authoritative source of truth for layout and
/// presentation constraints (e.g., [availableWidth]) during the formatting
/// and decoration stages.
@immutable
class LogContext {
  /// Creates a [LogContext].
  const LogContext({
    required this.availableWidth,
    this.arbitraryData = const {},
  });

  /// The maximum horizontal space available for log content, in terminal cells.
  ///
  /// Formatters and decorators SHOULD strictly respect this width to ensure
  /// consistent alignment and prevent overflow.
  final int availableWidth;

  /// Additional arbitrary data for extensibility.
  final Map<String, Object?> arbitraryData;
}

/// Represents a single line in a log output, composed of semantic segments.
@immutable
class LogLine {
  /// Creates a [LogLine] from a list of segments.
  const LogLine(this.segments);

  /// Creates a [LogLine] with a single plain text segment.
  factory LogLine.text(final String text) => LogLine([LogSegment(text)]);

  /// The semantic segments that make up this line.
  final List<LogSegment> segments;

  /// The visible width of the line.
  int get visibleLength =>
      segments.fold(0, (final sum, final s) => sum + s.text.visibleLength);

  @override
  String toString() => segments.map((final s) => s.text).join();
}

/// A semantic segment of a log line.
///
/// Holds the textual content and metadata (tags) describing it.
@immutable
class LogSegment {
  /// Creates a [LogSegment].
  const LogSegment(
    this.text, {
    this.tags = const {},
    this.style,
  });

  /// The textual content.
  final String text;

  /// Semantic tags describing this segment.
  final Set<LogTag> tags;

  /// Optional visual style suggestion.
  final LogStyle? style;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogSegment &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          style == other.style &&
          _setEquals(tags, other.tags);

  @override
  int get hashCode => text.hashCode ^ style.hashCode ^ Object.hashAll(tags);

  bool _setEquals<T>(final Set<T> a, final Set<T> b) {
    if (a.length != b.length) {
      return false;
    }
    return a.containsAll(b);
  }
}
