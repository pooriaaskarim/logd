part of '../handler.dart';

/// An encoder that automatically chooses between [AnsiEncoder] and
/// [PlainTextEncoder] based on terminal capabilities.
class AutoConsoleEncoder implements LogEncoder {
  /// Creates an [AutoConsoleEncoder].
  const AutoConsoleEncoder();

  @override
  void preamble(
    final HandlerContext context,
    final LogLevel level,
    final LogPipelineFactory factory, {
    final LogDocument? document,
  }) {
    _delegate.preamble(context, level, factory, document: document);
  }

  @override
  void postamble(
    final HandlerContext context,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) {
    _delegate.postamble(context, level, factory);
  }

  @override
  void encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level,
    final HandlerContext context,
    final LogPipelineFactory factory, {
    final int? width,
  }) {
    _delegate.encode(entry, document, level, context, factory, width: width);
  }

  LogEncoder get _delegate {
    try {
      if (io.stdout.supportsAnsiEscapes) {
        return const AnsiEncoder();
      }
    } catch (_) {
      // Accessing stdout in some environments might throw
    }
    return const PlainTextEncoder();
  }
}
