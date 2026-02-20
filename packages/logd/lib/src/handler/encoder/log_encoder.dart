part of '../handler.dart';

/// Encodes [LogDocument]s into a serialized format [T].
///
/// Encoders are responsible for converting the semantic, structured data
/// produced by formatters and decorators into a concrete format suitable for
/// transport by a [LogSink].
///
/// Common implementations include:
/// - [PlainTextEncoder]: Converts lines to a simple string.
/// - [AnsiEncoder]: Translates [LogStyle]s to ANSI escape codes.
/// - [HtmlEncoder]: Translates structure to HTML5 elements.
abstract interface class LogEncoder<T> {
  /// Encodes the [document] into a format [T].
  ///
  /// The [level] is provided to allow encoders to style the entire document
  /// based on severity (e.g. coloring the border of an HTML details
  /// implementation), though many encoders may ignore it.
  T encode(
    final LogDocument document,
    final LogLevel level, {
    final int? width,
  });
}

/// A simple encoder that joins lines with newlines, ignoring styles.
///
/// This is the default encoder for file sinks where usually raw text is
/// preferred over ANSI codes.
class PlainTextEncoder implements LogEncoder<String> {
  /// Creates a [PlainTextEncoder].
  const PlainTextEncoder();

  @override
  String encode(
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
