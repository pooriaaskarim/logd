part of '../handler.dart';

/// Manages the composition and application of [LogDecorator]s.
///
/// This class encapsulates the logic for sorting decorators based on their
/// structural priority (Content -> Box -> Hierarchy -> Visual) and applying
/// them to a [LogDocument].
@internal
class DecoratorPipeline {
  /// Creates a [DecoratorPipeline].
  const DecoratorPipeline(this.decorators);

  /// The list of decorators to apply.
  final List<LogDecorator> decorators;

  /// Applies the decorators to the [document].
  ///
  /// Decorators are first sorted by priority to ensure correct nesting:
  /// 1. [ContentDecorator] (innermost, modifies text)
  /// 2. [BoxDecorator] (wraps content)
  /// 3. [HierarchyDepthPrefixDecorator] (indents the box)
  /// 4. [VisualDecorator] (applies styles)
  /// 5. Others (outermost)
  LogDocument apply(
    final LogDocument document,
    final LogEntry entry,
  ) {
    if (decorators.isEmpty) {
      return document;
    }

    // Auto-sort to ensure correct visual composition.
    // Stable sort: Priority first, then original index.
    //
    // Deduplicate while preserving order to capture original indices.
    final uniqueDecorators = decorators.toSet().toList();
    final indexedDecorators = uniqueDecorators.asMap().entries.toList()
      ..sort((final a, final b) {
        final priorityComparison =
            _priority(a.value).compareTo(_priority(b.value));
        if (priorityComparison != 0) {
          return priorityComparison;
        }
        // Stability: preserve original order for same-priority items.
        return a.key.compareTo(b.key);
      });

    final sortedDecorators =
        indexedDecorators.map((final e) => e.value).toList();

    var result = document;
    for (final decorator in sortedDecorators) {
      result = decorator.decorate(result, entry);
    }

    return result;
  }

  /// Calculates the total padding width required by all decorators.
  ///
  /// This is used to determine the effective available width for the content.
  int calculateTotalPadding(final LogEntry entry) {
    var total = 0;
    for (final decorator in decorators) {
      total += decorator.paddingWidth(entry);
    }
    return total;
  }

  /// Calculates the padding reserved for structural decorators.
  ///
  /// Structural decorators (like boxes) reduce the "content limit", unlike
  /// visual decorators which might just add ANSI codes without taking up space.
  int calculateStructuralPadding(final LogEntry entry) {
    var total = 0;
    for (final decorator in decorators) {
      if (decorator is StructuralDecorator) {
        total += decorator.paddingWidth(entry);
      }
    }
    return total;
  }

  int _priority(final LogDecorator decorator) {
    if (decorator is ContentDecorator) {
      return 0;
    }
    if (decorator is StructuralDecorator) {
      // Within Structural, Box comes before Hierarchy (Indentation).
      // Box wraps content, Hierarchy indents the wrapped box.
      if (decorator is BoxDecorator) {
        return 1;
      }
      if (decorator is HierarchyDepthPrefixDecorator) {
        return 2;
      }
      return 3; // Unknown structural decorators
    }
    if (decorator is VisualDecorator) {
      return 4;
    }
    return 5; // Unknown other decorators
  }
}
