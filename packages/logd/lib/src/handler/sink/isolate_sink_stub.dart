library;

import 'dart:typed_data';
import '../../logger/logger.dart';
import '../engine/engine.dart';
import '../sink/sink.dart';

/// A fallback stub for [IsolateSink] on unsupported platforms (like Web).
///
/// Offloads log encoding/output processes to a background worker isolate.
/// Attempting to use this sink under Web results in an [UnsupportedError]
/// pointing the user to standard synchronous sinks.
base class IsolateSink extends LogSink<Uint8List> {
  /// Creates an [IsolateSink] stub.
  IsolateSink(this.target) : super(enabled: target.enabled) {
    throw UnsupportedError(
      'IsolateSink is only supported on native platforms (VM/Desktop/Mobile) '
      'because web browsers do not support multi-threading via Dart isolates. '
      'Consider using standard synchronous sinks directly under Web.',
    );
  }

  /// The underlying sink where logs are processed and output.
  final LogSink target;

  @override
  Future<void> output(
    final Uint8List document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) =>
      throw UnsupportedError(
        'IsolateSink is only supported on native platforms (VM/Desktop/Mobile) '
        'because web browsers do not support multi-threading via Dart isolates.'
        ' Consider using standard synchronous sinks directly under Web.',
      );
}

/// A fallback stub for [NativeIsolateSink] on unsupported platforms (like Web).
///
/// Offloads log encoding/output processes to a background worker isolate.
/// Attempting to use this sink under Web results in an [UnsupportedError]
/// pointing the user to standard synchronous sinks.
base class NativeIsolateSink extends LogSink<dynamic> {
  /// Creates a [NativeIsolateSink] stub.
  NativeIsolateSink(final LogSink target) : super(enabled: target.enabled) {
    throw UnsupportedError(
      'NativeIsolateSink is only supported on native platforms (VM/Desktop/Mobile) '
      'because web browsers do not support multi-threading via Dart isolates. '
      'Consider using standard synchronous sinks directly under Web.',
    );
  }

  @override
  Future<void> output(
    final dynamic document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) =>
      throw UnsupportedError(
        'NativeIsolateSink is only supported on native platforms '
        '(VM/Desktop/Mobile) because web browsers do not support '
        'multi-threading via Dart isolates.'
        ' Consider using standard synchronous sinks directly under Web.',
      );
}
