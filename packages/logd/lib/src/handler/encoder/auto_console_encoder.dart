part of '../handler.dart';

/// An encoder that automatically chooses between [AnsiEncoder] and
/// [PlainTextEncoder] based on terminal capabilities.
class AutoConsoleEncoder implements LogEncoder {
  /// Creates an [AutoConsoleEncoder].
  const AutoConsoleEncoder();

  @override
  void preamble(
    final HandlerContext context,
    final LogLevel level, {
    final LogDocument? document,
  }) {
    _delegate.preamble(context, level, document: document);
  }

  @override
  void postamble(final HandlerContext context, final LogLevel level) {
    _delegate.postamble(context, level);
  }

  @override
  void encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level,
    final HandlerContext context, {
    final int? width,
  }) {
    _delegate.encode(entry, document, level, context, width: width);
  }

  LogEncoder get _delegate => io.stdout.supportsAnsiEscapes
      ? const AnsiEncoder()
      : const PlainTextEncoder();
}
