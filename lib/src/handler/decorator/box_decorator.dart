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
final class BoxDecorator implements LogDecorator {
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

  /// Explicit control over ANSI color usage.
  ///
  /// If `null`, colors are enabled only if stdout supports ANSI escapes.
  final bool? useColors;

  /// The width of the box.
  ///
  /// If `null`, it will attempt to detect the terminal width at runtime.
  final int? lineLength;

  /// The visual style of the box borders.
  final BorderStyle borderStyle;

  late final bool _useColors = useColors ?? io.stdout.supportsAnsiEscapes;
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
  Iterable<String> decorate(
    final Iterable<String> lines,
    final LogLevel level,
  ) {
    final color = _useColors ? _levelColors[level] ?? '' : '';
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

    final reset = _useColors ? _ansiReset : '';
    final top = '$color$topLeft${horizontal * _lineLength}$topRight$reset';
    final bottom =
        '$color$bottomLeft${horizontal * _lineLength}$bottomRight$reset';

    final boxed = <String>[top];
    for (final line in lines) {
      for (final rawLine in line.split('\n')) {
        for (final wrapped in rawLine.wrapVisible(_lineLength)) {
          final padded = wrapped.padVisible(_lineLength);
          boxed.add('$color$vertical$reset$padded$color$vertical$reset');
        }
      }
    }
    boxed.add(bottom);

    return boxed;
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
