part of '../handler.dart';

/// A simple encoder that joins lines with newlines, ignoring styles.
///
/// This is the default encoder for file sinks where usually raw text is
/// preferred over ANSI codes.
class PlainTextEncoder implements LogEncoder {
  /// Creates a [PlainTextEncoder].
  const PlainTextEncoder();

  @override
  void preamble(
    final HandlerContext context,
    final LogLevel level, {
    final LogDocument? document,
  }) {}

  @override
  void postamble(final HandlerContext context, final LogLevel level) {}

  @override
  void encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level,
    final HandlerContext context, {
    final int? width,
  }) {
    if (document.nodes.isEmpty) {
      return;
    }

    // 1. Calculate physical layout
    final totalWidth = width ?? 80;
    final layoutEngine = TerminalLayout(width: totalWidth);
    final physicalDoc = layoutEngine.layout(document, level);

    // 2. Encode
    for (final line in physicalDoc.lines) {
      context.writeString(line.toString());
      context.addByte(0x0A); // '\n'
    }
  }
}
