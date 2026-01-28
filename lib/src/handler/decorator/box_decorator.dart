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

    // Measure actual content width (includes any prefixes added by prior
    // decorators)
    final linesList = lines.toList();

    // Auto-wrap lines that exceed the available content width - REMOVED.
    // Normalized by Handler now.
    final wrappedLines = linesList;

    int maxWidth = 0;
    for (final line in wrappedLines) {
      final w = line.visibleLength;
      if (w > maxWidth) {
        maxWidth = w;
      }
    }

    // Use the measured width as the base, but at least fill availableWidth
    // for consistent alignment across log entries.
    final contentWidth = maxWidth.clamp(context.availableWidth, 1000);

    final topBorderSegment = LogSegment(
      '$topLeft${horizontal * contentWidth}$topRight',
      tags: const {LogTag.border},
    );
    yield LogLine([topBorderSegment]);

    for (var line in wrappedLines) {
      // Expand tabs to spaces to ensure visual alignment inside the box
      line = _expandTabs(line);

      final contentLen = line.visibleLength;
      final paddingLen = (contentWidth - contentLen).clamp(0, contentWidth);

      yield LogLine([
        LogSegment(vertical, tags: const {LogTag.border}),
        ...line.segments,
        LogSegment(' ' * paddingLen, tags: const {}),
        LogSegment(vertical, tags: const {LogTag.border}),
      ]);
    }

    final bottomBorderSegment = LogSegment(
      '$bottomLeft${horizontal * contentWidth}$bottomRight',
      tags: const {LogTag.border},
    );
    yield LogLine([bottomBorderSegment]);
  }

  LogLine _expandTabs(final LogLine line) {
    if (!line.toString().contains('\t')) {
      return line;
    }
    final newSegments = <LogSegment>[];
    var currentX = 0;
    for (final seg in line.segments) {
      if (!seg.text.contains('\t')) {
        newSegments.add(seg);
        currentX += seg.text.visibleLength;
        continue;
      }
      final buffer = StringBuffer();
      final text = seg.text;
      for (final char in text.characters) {
        if (char == '\t') {
          final spaces = 8 - (currentX % 8);
          buffer.write(' ' * spaces);
          currentX += spaces;
        } else {
          buffer.write(char);
          currentX += isWide(char) ? 2 : 1;
        }
      }
      newSegments.add(
        LogSegment(buffer.toString(), tags: seg.tags, style: seg.style),
      );
    }
    return LogLine(newSegments);
  }

  @override
  int paddingWidth(final LogEntry entry) => 2;

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
