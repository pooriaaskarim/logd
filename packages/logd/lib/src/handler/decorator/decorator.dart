part of '../handler.dart';

/// Base class for log document decorators, formally classified by their effect.
///
/// Decorators allow for post-processing the [LogDocument] after it has been
/// constructed. This hierarchy is [sealed] to ensure that all decorators
/// fall into one of the known categories, enabling automatic handling
/// of composition complexities.
sealed class LogDecorator {
  /// Constant constructor for subclasses.
  const LogDecorator();

  /// Decorates the [document] in-place based on the [entry], using [factory]
  /// for new nodes.
  ///
  /// All new nodes created by this decorator via the [factory] participate
  /// in the pool lifecycle and will be released with the document.
  void decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogNodeFactory factory,
  );

  /// Returns the width in terminal cells this decorator adds to each line.
  int paddingWidth(final LogEntry entry) => 0;
}

/// A decorator that modifies the content or metadata of a [LogDocument].
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
