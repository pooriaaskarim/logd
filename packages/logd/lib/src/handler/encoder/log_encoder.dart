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
/// - [MarkdownEncoder]: Translates structure to Markdown.
/// - [JsonEncoder]: Produces structured JSON.
/// - [ToonEncoder]: Produces TOON-formatted rows.
abstract interface class LogEncoder<T> {
  /// Returns the document start (e.g., HTML header or TOON header), if
  /// applicable.
  ///
  /// The [document] parameter allows encoders to access metadata (like
  /// column names or array titles) required for session-level headers.
  T? preamble(final LogLevel level, {final LogDocument? document}) => null;

  /// Returns the document end (e.g., HTML footer), if applicable.
  T? postamble(final LogLevel level) => null;

  /// Encodes the [document] into a format [T], using the original [entry] for
  /// data access.
  ///
  /// The [level] is typically derived from entry.level but provided
  /// explicitly for convenience in styling.
  T encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level, {
    final int? width,
  });
}
