part of '../handler.dart';

/// A [LogSink] that encodes and outputs logs to the system console.
@immutable
base class ConsoleSink extends EncodingSink<String> {
  /// Creates a [ConsoleSink].
  ///
  /// - [lineLength]: The max line length. If null, terminal width is used.
  /// - [encoder]: The encoder used to serialize logs (default:
  ///   [AutoConsoleEncoder]).
  /// - [enabled]: Whether the sink is currently active.
  const ConsoleSink({
    this.lineLength,
    super.encoder = const AutoConsoleEncoder(),
    super.enabled,
  }) : super(
          delegate: _staticWrite,
          preferredWidth: lineLength,
        );

  /// The maximum line length for the output.
  final int? lineLength;

  static void _staticWrite(final String data) => io.stdout.writeln(data);

  @override
  int? get preferredWidth =>
      lineLength ?? (io.stdout.hasTerminal ? io.stdout.terminalColumns : 80);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ConsoleSink &&
          runtimeType == other.runtimeType &&
          lineLength == other.lineLength &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(runtimeType, lineLength, enabled);
}
