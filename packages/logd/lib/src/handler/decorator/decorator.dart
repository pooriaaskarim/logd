part of '../handler.dart';

/// Base class for log line decorators, formally classified by their effect.
///
/// Decorators allow for post-processing log lines after they have been
/// formatted. This hierarchy is [sealed] to ensure that all decorators
/// fall into one of the known categories, enabling automatic handling
/// of composition complexities.
sealed class LogDecorator {
  /// Constant constructor for subclasses.
  const LogDecorator();

  /// Decorates the [lines] based on the [entry].
  ///
  /// Returns an [Iterable] of decorated [LogLine]s.
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
    final LogContext context,
  );

  /// Returns the width in terminal cells this decorator adds to each line.
  int paddingWidth(final LogEntry entry) => 0;
}

/// A decorator that modifies the content or metadata of log lines.
/// Examples: masking PII, adding prefixes [PrefixDecorator].
abstract class ContentDecorator extends LogDecorator {
  /// Constant constructor for subclasses.
  const ContentDecorator();
}

/// A decorator that modifies the layout or structure of log output.
/// Examples: [BoxDecorator], adding dividers, or indentation.
abstract class StructuralDecorator extends LogDecorator {
  /// Constant constructor for subclasses.
  const StructuralDecorator();
}

/// A decorator that modifies the visual appearance of characters.
/// Examples: [StyleDecorator], bolding, or italics.
abstract class VisualDecorator extends LogDecorator {
  /// Constant constructor for subclasses.
  const VisualDecorator();
}
