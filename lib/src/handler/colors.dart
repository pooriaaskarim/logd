part of 'handler.dart';

/// Abstract color definitions for log rendering.
///
/// These colors are semantic and do not imply any specific rendering technology
/// (like ANSI). Sinks are free to interpret these colors as they see fit, or
/// ignore them entirely.
enum LogColor {
  black,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  white,
  brightBlack,
  brightRed,
  brightGreen,
  brightYellow,
  brightBlue,
  brightMagenta,
  brightCyan,
  brightWhite;
}

/// Configuration for color schemes based on log levels.
@immutable
class ColorScheme {
  /// Creates a color scheme.
  const ColorScheme({
    required this.trace,
    required this.debug,
    required this.info,
    required this.warning,
    required this.error,
  });

  final LogColor trace;
  final LogColor debug;
  final LogColor info;
  final LogColor warning;
  final LogColor error;

  LogColor colorForLevel(final LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return trace;
      case LogLevel.debug:
        return debug;
      case LogLevel.info:
        return info;
      case LogLevel.warning:
        return warning;
      case LogLevel.error:
        return error;
    }
  }

  /// Default color scheme.
  static const defaultScheme = ColorScheme(
    trace: LogColor.green,
    debug: LogColor.white,
    info: LogColor.blue,
    warning: LogColor.yellow,
    error: LogColor.red,
  );

  /// Dark theme scheme with brighter colors for better visibility.
  static const darkScheme = ColorScheme(
    trace: LogColor.brightGreen,
    debug: LogColor.brightWhite,
    info: LogColor.brightBlue,
    warning: LogColor.brightYellow,
    error: LogColor.brightRed,
  );

  /// Pastel theme scheme with softer colors.
  static const pastelScheme = ColorScheme(
    trace: LogColor.green,
    debug: LogColor.cyan,
    info: LogColor.brightCyan,
    warning: LogColor.brightYellow,
    error: LogColor.brightRed,
  );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ColorScheme &&
          trace == other.trace &&
          debug == other.debug &&
          info == other.info &&
          warning == other.warning &&
          error == other.error;

  @override
  int get hashCode => Object.hash(trace, debug, info, warning, error);
}

/// Configuration for fine-grained color application in [ColorDecorator].
@immutable
class ColorConfig {
  /// Creates a color application configuration.
  const ColorConfig({
    this.colorHeader = true,
    this.colorBody = true,
    this.colorBorder = true,
    this.colorStackFrame = true,
    this.headerBackground = false,
  });

  /// Whether to color header lines (timestamp, level, logger name).
  final bool colorHeader;

  /// Whether to color the main message body.
  final bool colorBody;

  /// Whether to color structural borders (e.g., box borders).
  final bool colorBorder;

  /// Whether to color stack trace frames.
  final bool colorStackFrame;

  /// Whether to use a background color for headers instead of foreground.
  final bool headerBackground;

  /// Default configuration: color everything, no header background.
  static const all = ColorConfig();

  /// Color everything except borders.
  static const noBorders = ColorConfig(
    colorHeader: true,
    colorBody: true,
    colorBorder: false,
    colorStackFrame: true,
  );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ColorConfig &&
          colorHeader == other.colorHeader &&
          colorBody == other.colorBody &&
          colorBorder == other.colorBorder &&
          colorStackFrame == other.colorStackFrame &&
          headerBackground == other.headerBackground;

  @override
  int get hashCode => Object.hash(
      colorHeader, colorBody, colorBorder, colorStackFrame, headerBackground);
}
