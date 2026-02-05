part of '../handler.dart';

/// A [LogDecorator] that wraps formatted lines in an ASCII box.
///
/// This decorator adds visual borders around pre-formatted log lines,
/// providing a highly visual output. It supports multiple border styles
/// and optional ANSI color coding based on log level.
///
/// Example usage:
/// ```dart
/// Handler(
///   formatter: StructuredFormatter(),
///   decorators: [
///     BoxDecorator(
///       border: BoxBorder.rounded,
///     ),
///   ],
///   sink: ConsoleSink(),
/// )
/// ```
@immutable
final class BoxDecorator extends StructuralDecorator {
  /// Creates a [BoxDecorator] with customizable styling.
  ///
  /// - [border]: The visual style of the box borders
  /// (rounded, sharp, double).
  const BoxDecorator({
    this.border = BoxBorderStyle.rounded,
  });

  /// The visual style of the box borders.
  final BoxBorderStyle border;

  @override
  LogDocument decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogContext context,
  ) =>
      LogDocument(
        nodes: [
          BoxNode(
            children: document.nodes,
            border: border,
          ),
        ],
        metadata: document.metadata,
      );

  @override
  int paddingWidth(final LogEntry entry) => 4;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is BoxDecorator &&
          runtimeType == other.runtimeType &&
          border == other.border;

  @override
  int get hashCode => border.hashCode;
}
