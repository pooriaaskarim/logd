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
///       colorScheme: AnsiColorScheme.defaultScheme,
///     ),
///   ],
///   sink: ConsoleSink(),
/// )
/// ```
@immutable
final class BoxDecorator extends StructuralDecorator {
  /// Creates a [BoxDecorator] with customizable styling.
  ///
  /// - [useColors]: Whether to use ANSI colors for borders
  /// (attempts auto-detection if null).
  /// - [lineLength]: The total width of the box including borders.
  /// If `null`, attempts to detect terminal width or defaults to 80.
  /// Must be at least 3 to accommodate borders and content.
  /// - [borderStyle]: The visual style of the box borders
  /// (rounded, sharp, double).
  /// - [colorScheme]: Defines which colors to use for different log levels.
  /// Defaults to [AnsiColorScheme.defaultScheme].
  BoxDecorator({
    this.useColors,
    this.lineLength,
    this.borderStyle = BorderStyle.rounded,
    this.colorScheme = AnsiColorScheme.defaultScheme,
  }) {
    if (lineLength != null && lineLength! < 3) {
      throw ArgumentError(
        'Invalid lineLength: $lineLength.'
        ' Must be at least 3 to accommodate borders.',
      );
    }
  }

  /// The visual style of the box borders.
  final BorderStyle borderStyle;

  /// The maximum max width of the box.
  final int? lineLength;

  /// Whether to apply colors to the border.
  final bool? useColors;

  /// Color scheme for border coloring.
  final AnsiColorScheme colorScheme;

  late final int _lineLength = (lineLength ??
          (io.stdout.hasTerminal ? io.stdout.terminalColumns - 4 : 80))
      .clamp(3, double.infinity)
      .toInt();

  static const _ansiReset = '\x1B[0m';

  @override
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
  ) sync* {
    final enabled = useColors ?? io.stdout.supportsAnsiEscapes;
    final color =
        enabled ? colorScheme.colorForLevel(entry.level).foreground : '';
    final reset = enabled ? _ansiReset : '';
    final String topLeft,
        topRight,
        bottomLeft,
        bottomRight,
        horizontal,
        vertical;
    switch (borderStyle) {
      case BorderStyle.rounded:
        topLeft = '╭';
        topRight = '╮';
        bottomLeft = '╰';
        bottomRight = '╯';
        horizontal = '─';
        vertical = '│';
        break;
      case BorderStyle.sharp:
        topLeft = '┌';
        topRight = '┐';
        bottomLeft = '└';
        bottomRight = '┘';
        horizontal = '─';
        vertical = '│';
        break;
      case BorderStyle.double:
        topLeft = '╔';
        topRight = '╗';
        bottomLeft = '╚';
        bottomRight = '╝';
        horizontal = '═';
        vertical = '║';
        break;
    }

    // Idempotency: If all input lines are already boxed, yield as-is
    final linesList = lines.toList();
    if (linesList.isNotEmpty &&
        linesList.every((final line) => line.tags.contains(LogLineTag.boxed))) {
      yield* linesList;
      return;
    }

    final borderTags = {
      LogLineTag.border,
      LogLineTag.boxed,
      if (enabled) LogLineTag.ansiColored,
    };

    final top = LogLine(
      '$color$topLeft${horizontal * _lineLength}$topRight$reset',
      tags: borderTags,
    );
    final bottom = LogLine(
      '$color$bottomLeft${horizontal * _lineLength}$bottomRight$reset',
      tags: borderTags,
    );

    final boxed = <LogLine>[top];
    for (final line in lines) {
      // Idempotency: Skip already-boxed lines
      if (line.tags.contains(LogLineTag.boxed)) {
        yield line;
        continue;
      }

      // Robustness: Split by newline in case line.text has them
      final textLines = line.text.split('\n');
      for (final textLine in textLines) {
        for (final wrapped in textLine.wrapVisiblePreserveAnsi(_lineLength)) {
          // Use ANSI-aware padding to style padding within the line's ANSI
          final padded = wrapped.padRightVisiblePreserveAnsi(_lineLength);
          boxed.add(
            LogLine(
              '$color$vertical$reset$padded$color$vertical$reset',
              tags: {...line.tags, ...borderTags},
            ),
          );
        }
      }
    }
    boxed.add(bottom);

    yield* boxed;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is BoxDecorator &&
          runtimeType == other.runtimeType &&
          useColors == other.useColors &&
          lineLength == other.lineLength &&
          borderStyle == other.borderStyle &&
          colorScheme == other.colorScheme;

  @override
  int get hashCode =>
      useColors.hashCode ^
      lineLength.hashCode ^
      borderStyle.hashCode ^
      colorScheme.hashCode;
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
