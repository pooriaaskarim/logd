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
///       borderStyle: BorderStyle.rounded,
///
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
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    final topLeft = _char(borderStyle, 0);
    final topRight = _char(borderStyle, 1);
    final bottomLeft = _char(borderStyle, 2);
    final bottomRight = _char(borderStyle, 3);
    final horizontal = _char(borderStyle, 4);
    final vertical = _char(borderStyle, 5);

    if (lines.isNotEmpty) {
      final firstLine = lines.first;
      if (firstLine.segments.isNotEmpty &&
          firstLine.segments.first.tags.contains(LogTag.border)) {
        yield* lines;
        return;
      }
    }

    // Calculate dynamic width based on content
    int maxContentWidth = 0;
    for (final line in lines) {
      final len = line.visibleLength;
      if (len > maxContentWidth) {
        maxContentWidth = len;
      }
    }

    // Ensure box wraps content if it's wider than configured availableWidth
    // availableWidth includes borders (2 chars).
    // width to be at least context.availableWidth.
    final minWidth = context.availableWidth;
    final contentWidthIfNeeded = maxContentWidth + 2;
    final width =
        contentWidthIfNeeded > minWidth ? contentWidthIfNeeded : minWidth;
    final effectiveContentWidth = width - 2;

    final topBorderSegment = LogSegment(
      '$topLeft${horizontal * (width - 2)}$topRight',
      tags: const {LogTag.border},
    );
    yield LogLine([topBorderSegment]);

    for (final line in lines) {
      final contentLen = line.visibleLength;
      final paddingLen =
          (effectiveContentWidth - contentLen).clamp(0, effectiveContentWidth);
      String paddingFn(final int p) => ' ' * p;

      yield LogLine([
        LogSegment(vertical, tags: const {LogTag.border}),
        ...line.segments,
        LogSegment(paddingFn(paddingLen), tags: const {}),
        LogSegment(vertical, tags: const {LogTag.border}),
      ]);
    }

    final bottomBorderSegment = LogSegment(
      '$bottomLeft${horizontal * (width - 2)}$bottomRight',
      tags: const {LogTag.border},
    );
    yield LogLine([bottomBorderSegment]);
  }

  String _char(final BorderStyle style, final int index) {
    const rounded = ['╭', '╮', '╰', '╯', '─', '│'];
    const sharp = ['┌', '┐', '└', '┘', '─', '│'];
    const doubleStyle = ['╔', '╗', '╚', '╝', '═', '║'];

    switch (style) {
      case BorderStyle.rounded:
        return rounded[index];
      case BorderStyle.sharp:
        return sharp[index];
      case BorderStyle.double:
        return doubleStyle[index];
    }
  }

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
enum BorderStyle {
  /// Rounded corners (╭─╮ │ ╰─╯)
  rounded,

  /// Sharp corners (┌─┐ │ └─┘)
  sharp,

  /// Double-line borders (╔═╗ ║ ╚═╝)
  double,
}
