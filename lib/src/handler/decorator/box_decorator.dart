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
///     BoxDecorator(borderStyle: BorderStyle.rounded),
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
  /// - [lineLength]: The width of the box.
  /// If `null`, attempts to detect terminal width or defaults to 80.
  /// - [borderStyle]: The visual style of the box borders
  /// (rounded, sharp, double).
  BoxDecorator({
    this.useColors,
    this.lineLength,
    this.borderStyle = BorderStyle.rounded,
  });

  /// The visual style of the box borders.
  final BorderStyle borderStyle;

  /// The maximum max width of the box.
  final int? lineLength;

  /// Whether to apply colors to the border.
  final bool? useColors;

  late final int _lineLength = lineLength ??
      (io.stdout.hasTerminal ? io.stdout.terminalColumns - 4 : 80);

  static const _ansiReset = '\x1B[0m';
  static final _levelColors = {
    LogLevel.trace: '\x1B[90m', // Grey
    LogLevel.debug: '\x1B[37m', // White
    LogLevel.info: '\x1B[32m', // Green
    LogLevel.warning: '\x1B[33m', // Yellow
    LogLevel.error: '\x1B[31m', // Red
  };

  @override
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
  ) sync* {
    final enabled = useColors ?? io.stdout.supportsAnsiEscapes;
    final color = enabled ? (_levelColors[entry.level] ?? '') : '';
    final reset = enabled ? _ansiReset : '';

    String topLeft, topRight, bottomLeft, bottomRight, horizontal, vertical;

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
      // Idempotency: Skip if already boxed
      // (This prevents nested boxes if a line is already part of one)
      if (line.tags.contains(LogLineTag.boxed)) {
        yield line;
        continue;
      }

      // Robustness: Split by newline in case line.text has them
      final textLines = line.text.split('\n');
      for (final textLine in textLines) {
        for (final wrapped in textLine.wrapVisible(_lineLength)) {
          final padded = wrapped.padVisible(_lineLength);
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
          borderStyle == other.borderStyle;

  @override
  int get hashCode =>
      useColors.hashCode ^ lineLength.hashCode ^ borderStyle.hashCode;
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
