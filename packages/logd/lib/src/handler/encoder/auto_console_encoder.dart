part of '../handler.dart';

/// An encoder that automatically chooses between [AnsiEncoder] and
/// [PlainTextEncoder] based on terminal capabilities.
class AutoConsoleEncoder implements LogEncoder<String> {
  /// Creates an [AutoConsoleEncoder].
  const AutoConsoleEncoder();

  @override
  String? preamble(final LogLevel level, {final LogDocument? document}) =>
      _delegate.preamble(level, document: document);

  @override
  String? postamble(final LogLevel level) => _delegate.postamble(level);

  @override
  String encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level, {
    final int? width,
  }) =>
      _delegate.encode(entry, document, level, width: width);

  LogEncoder<String> get _delegate => io.stdout.supportsAnsiEscapes
      ? const AnsiEncoder()
      : const PlainTextEncoder();
}
