/// The orchestration layer for the Logd pipeline.
///
/// This library defines the [Handler] and the core models for processing
/// logs. It uses a structured [LogDocument] as the intermediate representation.
/// 
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
  @internal
  Future<void> log(final LogEntry entry) async {
    if (filters.any((final filter) => !filter.shouldLog(entry))) {
      return;
    }

    // 1. Context for the pipeline
    const context = LogContext();

    // 2. Delegate decorator logic to pipeline component
    final pipeline = DecoratorPipeline(decorators);

    // 3. Format: Document production (Level 2: Semantic Literacy)
    final document = formatter.format(entry, context);

    // 4. Decorate: Document transformation
    final decorated = pipeline.apply(document, entry, context);

    // 5. Output: Emission
    if (decorated.nodes.isNotEmpty) {
      await sink.output(decorated, entry.level, context: context);
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
/// The [LogContext] acts as a transport for semantic metadata and arbitrary
/// user data through the formatting and decoration stages. It is purposefully
/// width-agnostic, as geometric constraints are handled at the emission layer.
///
/// Currently [LogContext] is not really used by any formatter or decorator. it
/// is kept merly for probable future extensibility.
@immutable
class LogContext {
  /// Creates a [LogContext].
  const LogContext({
    this.arbitraryData = const {},
  });

  /// Additional arbitrary data for extensibility.
  final Map<String, Object?> arbitraryData;
}
