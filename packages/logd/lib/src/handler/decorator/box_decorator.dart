part of '../handler.dart';

/// A [LogDecorator] that wraps logs in a box.
///
/// This decorator adds structural borders around a [LogDocument] content,
/// providing a highly visual output. It supports multiple border styles
/// and optional ANSI color coding based on log level.
///
/// Example usage:
/// ```dart
/// Handler(
///   formatter: StructuredFormatter(),
///   decorators: [
///     BoxDecorator(
///       borderStyle: BorderStyle.rounded,
///     ),
///   ],
///   sink: ConsoleSink(),
/// )
/// ```
@immutable
final class BoxDecorator extends StructuralDecorator {
  /// Creates a [BoxDecorator] with customizable styling.
  ///
  /// - [borderStyle]: The visual style of the box borders
  /// (rounded, sharp, double).
  const BoxDecorator({
    this.borderStyle = BorderStyle.rounded,
  });

  /// The visual style of the box borders.
  final BorderStyle borderStyle;

  @override
  void decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogNodeFactory factory,
  ) {
    final box = factory.checkoutBox()
      ..border = borderStyle
      ..style = null
      ..children.addAll(document.nodes);
    // Repurpose the existing document rather than allocating a new one.
    document.nodes
      ..clear()
      ..add(box);
  }

  @override
  int paddingWidth(final LogEntry entry) => 4;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is BoxDecorator &&
          runtimeType == other.runtimeType &&
          borderStyle == other.borderStyle;

  @override
  int get hashCode => borderStyle.hashCode;
}

/// Visual styles for box borders.
typedef BorderStyle = BoxBorderStyle;
