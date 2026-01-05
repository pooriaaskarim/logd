library;

import 'package:meta/meta.dart';

import '../../logd.dart';

/// ANSI escape codes for basic 16-color terminal support.
enum AnsiColor {
  /// Standard colors (30-37)
  black(30),
  red(31),
  green(32),
  yellow(33),
  blue(34),
  magenta(35),
  cyan(36),
  white(37),

  /// Bright colors (90-97)
  brightBlack(90),
  brightRed(91),
  brightGreen(92),
  brightYellow(93),
  brightBlue(94),
  brightMagenta(95),
  brightCyan(96),
  brightWhite(97);

  const AnsiColor(this.code);

  final int code;

  /// ANSI escape sequence for this color (foreground).
  String get foreground => '\x1B[${code}m';

  /// ANSI escape sequence for this color (background, code + 10).
  String get background => '\x1B[${code + 10}m';
}

/// ANSI style modifiers.
enum AnsiStyle {
  bold(1),
  dim(2),
  italic(3),
  underline(4),
  blink(5),
  reverse(7),
  hidden(8),
  strikethrough(9);

  const AnsiStyle(this.code);

  final int code;

  /// ANSI escape sequence for this style.
  String get sequence => '\x1B[${code}m';
}

/// Configuration for ANSI color customization across log levels.
@immutable
class AnsiColorScheme {
  /// Creates a color scheme with explicit color mappings for each log level.
  const AnsiColorScheme({
    required this.trace,
    required this.debug,
    required this.info,
    required this.warning,
    required this.error,
  });

  /// Color for trace level logs.
  final AnsiColor trace;

  /// Color for debug level logs.
  final AnsiColor debug;

  /// Color for info level logs.
  final AnsiColor info;

  /// Color for warning level logs.
  final AnsiColor warning;

  /// Color for error level logs.
  final AnsiColor error;

  /// Returns the color for a given log level.
  AnsiColor colorForLevel(final LogLevel level) {
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

  /// Default color scheme:
  /// - trace: green
  /// - debug: white
  /// - info: blue
  /// - warning: yellow
  /// - error: red
  static const defaultScheme = AnsiColorScheme(
    trace: AnsiColor.green,
    debug: AnsiColor.white,
    info: AnsiColor.blue,
    warning: AnsiColor.yellow,
    error: AnsiColor.red,
  );

  /// Dark theme scheme with brighter colors for better visibility.
  static const darkScheme = AnsiColorScheme(
    trace: AnsiColor.brightGreen,
    debug: AnsiColor.brightWhite,
    info: AnsiColor.brightBlue,
    warning: AnsiColor.brightYellow,
    error: AnsiColor.brightRed,
  );

  /// Pastel theme scheme with softer colors.
  static const pastelScheme = AnsiColorScheme(
    trace: AnsiColor.green,
    debug: AnsiColor.cyan,
    info: AnsiColor.brightCyan,
    warning: AnsiColor.brightYellow,
    error: AnsiColor.brightRed,
  );
}

/// Configuration for fine-grained color application in [AnsiColorDecorator].
@immutable
class AnsiColorConfig {
  /// Creates a color application configuration.
  const AnsiColorConfig({
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
  ///
  /// When true, combines bold style with level color.
  final bool headerBackground;

  /// Default configuration: color everything, no header background.
  static const all = AnsiColorConfig();

  /// Color only headers.
  static const headerOnly = AnsiColorConfig(
    colorHeader: true,
    colorBody: false,
    colorBorder: false,
    colorStackFrame: false,
  );

  /// Color only: message body.
  static const bodyOnly = AnsiColorConfig(
    colorHeader: false,
    colorBody: true,
    colorBorder: false,
    colorStackFrame: false,
  );

  /// Color everything except borders.
  static const noBorders = AnsiColorConfig(
    colorHeader: true,
    colorBody: true,
    colorBorder: false,
    colorStackFrame: true,
  );
}
