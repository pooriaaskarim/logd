part of '../handler.dart';

/// Base interface for log line decorators.
///
/// Decorators allow for post-processing log lines after they have been
/// formatted. Common use cases include adding ANSI color codes, adding
/// line prefixes, or stripping metadata.
abstract interface class LogDecorator {
  /// Constant constructor for subclasses.
  const LogDecorator();

  /// Decorates the [lines] based on the [level].
  ///
  /// Returns an [Iterable] of decorated strings.
  Iterable<String> decorate(
    final Iterable<String> lines,
    final LogLevel level,
  );
}
