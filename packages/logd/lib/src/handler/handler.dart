/// The orchestration layer for the Logd pipeline.
///
/// This library defines the [Handler] and the core models for processing
/// logs:
/// - [LogFormatter] for structure.
/// - [LogDecorator] for layout and style.
/// - [LogSink] for output.
/// - [LogDocument] as the intermediate representation.
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

import '../core/theme/log_theme.dart';
import '../core/utils/utils.dart';
import '../logger/logger.dart';

import '../time/timestamp.dart';

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
part 'formatter/markdown_formatter.dart';
part 'formatter/metadata/log_metadata.dart';
part 'formatter/plain_formatter.dart';
part 'formatter/structured_formatter.dart';
part 'encoder/ansi_encoder.dart';
part 'encoder/html_encoder.dart';
part 'encoder/log_encoder.dart';
part 'encoder/markdown_encoder.dart';
part 'encoder/terminal_layout.dart';
part 'formatter/toon_formatter.dart';
part 'model/log_content.dart';
part 'model/log_document.dart';
part 'model/log_layout.dart';
part 'model/physical_document.dart';
part 'model/styled_text.dart';
part 'pipeline/decorator_pipeline.dart';
part 'encoder/adapter/ansi_encoder_adapter.dart';
part 'sink/console_sink.dart';
part 'sink/encoding_sink.dart';
part 'sink/file_sink.dart';
part 'sink/html_sink.dart';
part 'sink/multi_sink.dart';
part 'sink/markdown_sink.dart';
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

    // Delegate decorator logic to pipeline component.
    final pipeline = DecoratorPipeline(decorators);

    // Calculate total width consumed by ALL decorators per line.
    final totalPadding = pipeline.calculateTotalPadding(entry);
    final structuralPadding = pipeline.calculateStructuralPadding(entry);

    final context = LogContext(
      availableWidth: (totalWidth - totalPadding).clamp(1, totalWidth),
      totalWidth: totalWidth,
      contentLimit: (totalWidth - structuralPadding).clamp(1, totalWidth),
    );

    // 1. Format: Document production (Level 2: Semantic Literacy)
    var document = formatter.format(entry, context);

    // 2. Decorate: Document transformation (Level 4: Structural Power)
    document = pipeline.apply(document, entry, context);

    // 3. Sink: Document emission
    if (document.nodes.isNotEmpty) {
      await sink.output(document, entry.level, context: context);
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

  /// The total terminal/configured width for the log entry.
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
