library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/context/context.dart';
import '../core/context/io/file_system.dart';

import '../core/utils/utils.dart';
import '../logger/logger.dart';
import '../stack_trace/stack_trace.dart';
import '../time/timestamp.dart';
part 'model/log_document.dart';
part 'model/log_content.dart';
part 'model/log_layout.dart';
part 'model/physical_document.dart';
part 'model/log_text.dart';
part 'model/log_context.dart';
part 'model/log_line.dart';
part 'model/log_metadata.dart';
part 'style/log_tag.dart';
part 'style/log_color.dart';
part 'style/log_style.dart';
part 'style/log_theme.dart';
part 'style/ansi_palette.dart';
part 'decorator/box_decorator.dart';
part 'decorator/decorator.dart';
part 'decorator/hierarchy_depth_prefix_decorator.dart';
part 'decorator/prefix_decorator.dart';
part 'decorator/style_decorator.dart';
part 'decorator/suffix_decorator.dart';
part 'filter/filter.dart';
part 'filter/level_filter.dart';
part 'filter/regex_filter.dart';
part 'formatter/formatter.dart';
part 'formatter/json_formatter.dart';
part 'formatter/plain_formatter.dart';
part 'formatter/structured_formatter.dart';
part 'formatter/toon_formatter.dart';
part 'encoder/terminal_layout.dart';
part 'encoder/ansi_encoder.dart';
part 'encoder/html_encoder.dart';
part 'encoder/json_encoder.dart';
part 'encoder/markdown_encoder.dart';
part 'encoder/log_encoder.dart';
part 'sink/console_sink.dart';
part 'sink/encoding_sink.dart';
part 'sink/file_sink.dart';
part 'sink/html_layout_sink.dart';
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

    // 1. Initial Format -> LogDocument
    LogDocument tree = formatter.format(entry, context).copyWith(
      metadata: {
        'width': context.totalWidth,
        'contentLimit': context.contentLimit,
      },
    );

    // 2. Decorate
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
      tree = decorator.decorate(tree, entry, context);
    }

    // 3. Final Output
    if (tree.nodes.isNotEmpty) {
      await sink.output(tree, entry.level);
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
