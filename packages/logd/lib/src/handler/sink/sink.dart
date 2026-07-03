library;

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/utils/utils.dart';
import '../../logger/logger.dart';
import '../document/document.dart';
import '../encoder/encoder.dart';
import '../engine/engine.dart';
import '../io_stub.dart' if (dart.library.io) '../io_native.dart' as io;

part 'console_sink.dart';
part 'print_sink.dart';
part 'multi_sink.dart';
part 'encoding_sink.dart';
part 'network_sink.dart';

/// Abstract base class for outputting logs to a destination.
///
/// Sinks define the final destination of log data, such as the system console,
/// a local file, or a remote network endpoint.
abstract base class LogSink<T> {
  /// Creates a [LogSink].
  ///
  /// If [enabled] is `false`, the [output] method
  /// should not perform any action.
  const LogSink({
    this.enabled = true,
  });

  /// Whether this sink is currently active.
  final bool enabled;

  /// Outputs the [data] to the destination.
  ///
  /// The [entry] is the original log entry that produced this data.
  ///
  /// The [level] indicates the severity of the log entry that produced this
  /// data, which can be used by the sink for destination-specific logic (e.g.,
  /// using different output streams for errors).
  Future<void> output(
    final T data,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  );

  /// Performs cleanup, such as closing file handles or network connections.
  ///
  /// This should be called when the sink is no longer needed.
  Future<void> dispose() async {}
}
