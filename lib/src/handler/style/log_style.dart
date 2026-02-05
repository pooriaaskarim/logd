part of '../handler.dart';

/// Visual style suggestion for a log segment.
@immutable
class LogStyle {
  /// Creates a [LogStyle].
  const LogStyle({
    this.color,
    this.backgroundColor,
    this.bold,
    this.dim,
    this.italic,
    this.inverse,
    this.underline,
  });

  /// The suggested foreground color.
  final LogColor? color;

  /// The suggested background color.
  final LogColor? backgroundColor;

  /// Whether the text should be bold.
  final bool? bold;

  /// Whether the text should be dimmed (faint).
  final bool? dim;

  /// Whether the text should be italic.
  final bool? italic;

  /// Whether the text/background color should be inverted.
  final bool? inverse;

  /// Whether the text should be underlined.
  final bool? underline;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          backgroundColor == other.backgroundColor &&
          bold == other.bold &&
          dim == other.dim &&
          italic == other.italic &&
          inverse == other.inverse &&
          underline == other.underline;

  @override
  int get hashCode => Object.hash(
        color,
        backgroundColor,
        bold,
        dim,
        italic,
        inverse,
        underline,
      );
}
