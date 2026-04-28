/// The orchestration layer for the Logd pipeline.
///
/// This library defines the [Handler] and the core models for processing
/// logs. It uses a structured [LogDocument] as the intermediate representation.
///
library;

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' as io;
import 'dart:isolate';
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

part 'document/content_nodes.dart';
part 'document/layout_nodes.dart';
part 'document/log_document.dart';
part 'document/log_metadata.dart';
part 'document/styled_text.dart';
part 'document/toon_type.dart';
part 'layout/physical_document.dart';
part 'layout/render_tokens.dart';
part 'layout/terminal_layout.dart';
part 'engine/arena.dart';
part 'engine/arena_engine.dart';
part 'engine/engine.dart';
part 'engine/standard_engine.dart';
part 'engine/handler_context.dart';
part 'decorator/decoration_hint.dart';
part 'decorator/decorator.dart';
part 'decorator/decorator_pipeline.dart';
part 'decorator/box_decorator.dart';
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
part 'encoder/ansi_encoder.dart';
part 'encoder/ansi_encoder_adapter.dart';
part 'encoder/auto_console_encoder.dart';
part 'encoder/fast_string_writer.dart';
part 'encoder/html_encoder.dart';
part 'encoder/json_encoder.dart';
part 'encoder/log_encoder.dart';
part 'encoder/markdown_encoder.dart';
part 'encoder/plain_text_encoder.dart';
part 'encoder/toon_encoder.dart';
part 'sink/console_sink.dart';
part 'sink/encoding_sink.dart';
part 'sink/file_sink.dart';
part 'sink/multi_sink.dart';
part 'sink/network_sink.dart';
part 'sink/isolate_sink.dart';
part 'sink/print_sink.dart';
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
    this.engine = const StandardEngine(),
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

  /// Process the entry: filter, format, decorate, output.
  @internal
  Future<void> log(final LogEntry entry) async {
    if (filters.any((final filter) => !filter.shouldLog(entry))) {
      return;
    }

    await engine.execute(entry, formatter, decorators, sink);
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is Handler &&
          runtimeType == other.runtimeType &&
          formatter == other.formatter &&
          sink == other.sink &&
          engine == other.engine &&
          listEquals(filters, other.filters) &&
          listEquals(decorators, other.decorators);

  @override
  int get hashCode =>
      formatter.hashCode ^
      sink.hashCode ^
      engine.hashCode ^
      Object.hashAll(filters) ^
      Object.hashAll(decorators);
}
