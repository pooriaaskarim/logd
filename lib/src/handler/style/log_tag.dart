part of '../handler.dart';

/// Semantic tags describing the content of a [StyledText].
enum LogTag {
  /// General metadata like timestamp, level, or logger name.
  header,

  /// Information about where the log was emitted (file, line, function).
  origin,

  /// The primary log message body.
  message,

  /// Error information (exception message).
  error,

  /// Individual frame in a stack trace.
  stackFrame,

  /// Content related to the log level (e.g. the "[[INFO]]" text).
  level,

  /// Content related to the timestamp.
  timestamp,

  /// Content related to the logger name.
  loggerName,

  /// Structural lines like box borders or dividers.
  border,

  /// Tree-like hierarchy prefix.
  hierarchy,

  /// Content Prefix
  prefix,

  /// Content Suffix
  suffix,

  /// Semantic key (e.g. JSON key, TOON field name).
  key,

  /// Generic data value.
  value,

  /// Structural punctuation (e.g. braces, commas, delimiters).
  punctuation,
}
