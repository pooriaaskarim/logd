library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:characters/characters.dart';
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
part 'decorator/suffix_decorator.dart';
part 'decorator/style_decorator.dart';
part 'filter/filter.dart';
part 'filter/level_filter.dart';
part 'filter/regex_filter.dart';
part 'formatter/formatter.dart';
part 'formatter/html_formatter.dart';
part 'formatter/metadata/log_metadata.dart';
part 'formatter/json_formatter.dart';
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
  @internal
  Future<void> log(final LogEntry entry) async {
    if (filters.any((final filter) => !filter.shouldLog(entry))) {
      return;
    }

    /// Context for the pipeline, merging handler config and sink capabilities.
    final totalWidth = lineLength ?? sink.preferredWidth;

    // Calculate total width consumed by ALL decorators per line.
    var totalPadding = 0;
    var structuralPadding = 0;

    for (final decorator in decorators) {
      final padding = decorator.paddingWidth(entry);
      totalPadding += padding;
      if (decorator is StructuralDecorator) {
        structuralPadding += padding;
      }
    }

    final context = LogContext(
      availableWidth: (totalWidth - totalPadding).clamp(1, totalWidth),
      totalWidth: totalWidth,
      contentLimit: (totalWidth - structuralPadding).clamp(1, totalWidth),
    );

    // Wrap all content to the available width (Content Slot).
    // This normalize formatters (Active or Passive) to ensure they fit within
    // the layout reserved for them, preventing conflicts with decorators.
    Iterable<LogLine> lines = formatter
        .format(entry, context)
        .expand((final line) => line.wrap(context.availableWidth));

    /// Auto-sort to ensure correct visual composition:
    /// 1. ContentDecorator (Content mutation)
    /// 2. StructuralDecorator (Outer wrapping, e.g. Box, then Indentation)
    /// 3. VisualDecorator (Content styling, e.g. AnsiColors)
    ///
    /// Using a Set for deduplication to prevent redundant decorators.
    final sortedDecorators = decorators.toSet().toList()
      ..sort((final a, final b) {
        int priority(final LogDecorator decorator) {
          if (decorator is ContentDecorator) {
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
    final int? totalWidth,
    final int? contentLimit,
    this.arbitraryData = const {},
  })  : totalWidth = totalWidth ?? availableWidth,
        contentLimit = contentLimit ?? (totalWidth ?? availableWidth);

  /// The width available for the initial formatting of the content.
  final int availableWidth;

  /// The total terminal/configured width for the log entry.
  final int totalWidth;

  /// The layout width limit derived from [totalWidth] minus structural
  /// overheads
  /// (e.g. Box borders).
  ///
  /// Decorators that align content (like Suffix) or wrap structure (like Box)
  /// should respect this limit to ensure the final composition fits the
  /// display.
  final int contentLimit;

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
  ///
  /// Calculates the maximum terminal width across all physical lines generated
  /// by the segments, correctly accounting for TAB stops (8 cells) across
  /// segment boundaries.
  int get visibleLength {
    if (segments.isEmpty) {
      return 0;
    }

    var maxWidth = 0;
    var currentX = 0;

    for (final segment in segments) {
      final text = segment.text;
      if (text.isEmpty) {
        continue;
      }

      // Handle segments that might contain physical newlines
      final physicalLines = text.split(RegExp(r'\r?\n'));

      for (int i = 0; i < physicalLines.length; i++) {
        if (i > 0) {
          // New physical line within a segment
          if (currentX > maxWidth) {
            maxWidth = currentX;
          }
          currentX = 0;
        }

        final linePart = physicalLines[i].stripAnsi;
        for (final char in linePart.characters) {
          if (char == '\t') {
            currentX += 8 - (currentX % 8);
          } else {
            currentX += isWide(char) ? 2 : 1;
          }
        }
      }
    }

    return currentX > maxWidth ? currentX : maxWidth;
  }

  /// Wraps this line into multiple lines, preserving semantic segments.
  Iterable<LogLine> wrap(final int width, {final String indent = ''}) sync* {
    // If indent is provided, we need to wrap tighter so indented lines
    // don't exceed the width
    final indentWidth = indent.visibleLength;
    final wrapWidth =
        indentWidth > 0 ? (width - indentWidth).clamp(1, width) : width;

    final parts = segments.map((final s) => (s.text, (s.tags, s.style)));
    final wrapped = wrapWithData(
      parts,
      wrapWidth,
    );

    var isFirst = true;
    for (final lineParts in wrapped) {
      final lineSegments = lineParts
          .map(
            (final p) => LogSegment(
              p.$1,
              tags: p.$2.$1,
              style: p.$2.$2,
            ),
          )
          .toList();

      if (!isFirst && indent.isNotEmpty) {
        lineSegments.insert(0, LogSegment(indent));
      }

      yield LogLine(lineSegments);
      isFirst = false;
    }
  }

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
