/// The orchestration layer for the Logd pipeline.
///
/// This library defines the [Handler] and the core models for processing
/// logs. It uses a structured [LogDocument] as the intermediate representation.
///
library;

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

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
part 'encoder/auto_console_encoder.dart';
part 'encoder/fast_string_writer.dart';
part 'encoder/html_encoder.dart';
part 'encoder/json_encoder.dart';
part 'encoder/log_encoder.dart';
part 'encoder/markdown_encoder.dart';
part 'encoder/plain_text_encoder.dart';
part 'encoder/terminal_layout.dart';
part 'encoder/toon_encoder.dart';
part 'formatter/toon_formatter.dart';
part 'model/log_content.dart';
part 'model/decoration_hint.dart';
part 'model/log_arena.dart';
part 'model/handler_context.dart';
part 'model/log_document.dart';
part 'model/log_layout.dart';
part 'model/physical_document.dart';
part 'model/styled_text.dart';
part 'pipeline/decorator_pipeline.dart';
part 'encoder/adapter/ansi_encoder_adapter.dart';
part 'sink/console_sink.dart';
part 'sink/encoding_sink.dart';
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

  /// The formatter used to transform a [LogEntry] into a [LogDocument].
  final LogFormatter formatter;

  /// The sink where the formatted and decorated lines are sent.
  final LogSink sink;

  /// A list of filters applied to each [LogEntry] before any processing.
  ///
  /// All filters must return `true` for the log entry to be processed.
  final List<LogFilter> filters;

  /// A list of decorators applied to the [LogDocument] in order.
  final List<LogDecorator> decorators;

  /// Process the entry: filter, format, decorate, output.
  @internal
  Future<void> log(final LogEntry entry) async {
    if (filters.any((final filter) => !filter.shouldLog(entry))) {
      return;
    }

    final arena = LogArena.instance;
    final document = arena.checkoutDocument();

    try {
      // 1. Format: Populate the document using arena as factory
      formatter.format(entry, document, arena);

      // 2. Decorate: Transform document in-place
      if (decorators.isNotEmpty) {
        DecoratorPipeline(decorators).apply(document, entry, arena);
      }

      // 3. Output: Emission
      if (document.nodes.isNotEmpty) {
        await sink.output(document, entry, entry.level);
      }
    } finally {
      // 4. Deterministic release: Always return entire tree to pool
      document.releaseRecursive(arena);
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
