part of '../handler.dart';

/// A [LogSink] that encodes logs using a [LogEncoder] before writing to an
/// output.
///
/// This serves as an adapter between the structured [LogLine] world and
/// raw transport mechanism (File, Socket, Console).
base class EncodingSink<T> extends LogSink {
  /// Creates an [EncodingSink].
  ///
  /// - [encoder]: The encoder to serialize LogLines into [T].
  /// - [delegate]: The callback to transport the encoded data.
  /// - [preferredWidth]: The preferred width for wrapping logs (default: 100).
  EncodingSink({
    required this.encoder,
    required this.delegate,
    this.preferredWidth = 100,
    super.enabled,
  });

  /// The encoder used to serialize the log lines.
  final LogEncoder<T> encoder;

  /// The transport callback.
  final Future<void> Function(T data) delegate;

  @override
  final int preferredWidth;

  @override
  Future<void> output(
    final LogDocument document,
    final LogLevel level,
  ) async {
    if (!enabled) {
      return;
    }
    final data = encoder.encode(document, level);
    await delegate(data);
  }
}
