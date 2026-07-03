part of 'sink.dart';

/// A [LogSink] that outputs logs using the standard [print] function.
///
/// This sink is preferred in environments where `stdout` is not captured,
/// such as Flutter IDE consoles (VS Code, Android Studio).
@internal
@immutable
base class PrintSink extends EncodingSink {
  /// Creates a [PrintSink].
  ///
  /// - [lineLength]: The max line length for wrapping.
  /// - [encoder]: The encoder used to serialize logs (default:
  ///   [AutoConsoleEncoder]).
  /// - [enabled]: Whether the sink is currently active.
  const PrintSink({
    this.lineLength,
    super.encoder = const AutoConsoleEncoder(),
    super.enabled,
  }) : super(
          delegate: staticWrite,
          preferredWidth: lineLength,
        );

  /// The maximum line length for the output.
  final int? lineLength;

  @internal
  static void staticWrite(final Uint8List data) {
    final message = convert.utf8.decode(data);
    // Standard print() adds a newline, so we strip one trailing \n if present
    // because EncodingSink adds a trailing newline to the data.
    if (message.endsWith('\n')) {
      print(message.substring(0, message.length - 1));
    } else {
      print(message);
    }
  }

  @override
  int? get preferredWidth => lineLength ?? 80;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is PrintSink &&
          runtimeType == other.runtimeType &&
          lineLength == other.lineLength &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(runtimeType, lineLength, enabled);
}
