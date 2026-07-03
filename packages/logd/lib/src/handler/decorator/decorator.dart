library;

import 'package:meta/meta.dart';
import '../../core/theme/log_theme.dart';
import '../../core/utils/utils.dart';
import '../../logger/logger.dart';
import '../document/document.dart';
import '../engine/engine.dart';
import '../handler.dart' show LogFormatter, TerminalLayout;

part 'box_decorator.dart';
part 'decoration_hint.dart';
part 'decorator_pipeline.dart';
part 'hierarchy_depth_prefix_decorator.dart';
part 'prefix_decorator.dart';
part 'style_decorator.dart';
part 'suffix_decorator.dart';

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
    final LogPipelineFactory factory,
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
