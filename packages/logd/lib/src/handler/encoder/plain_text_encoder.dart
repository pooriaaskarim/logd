part of '../handler.dart';

/// A simple encoder that joins lines with newlines, ignoring styles.
///
/// This is the default encoder for file sinks where usually raw text is
/// preferred over ANSI codes.
class PlainTextEncoder implements LogEncoder<String> {
  /// Creates a [PlainTextEncoder].
  const PlainTextEncoder();

  @override
  String? preamble(final LogLevel level, {final LogDocument? document}) => null;

  @override
  String? postamble(final LogLevel level) => null;

  @override
  String encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level, {
    final int? width,
  }) {
    if (document.nodes.isEmpty) {
      return '';
    }

    // 1. Calculate physical layout
    final totalWidth = width ?? 80;
    final layoutEngine = TerminalLayout(width: totalWidth);
    final physicalDoc = layoutEngine.layout(document, level);

    // 2. Encode
    final buffer = StringBuffer();
    for (final line in physicalDoc.lines) {
      buffer.writeln(line.toString());
    }

    return buffer.toString().trimRight();
  }
}
