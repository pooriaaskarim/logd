import 'package:meta/meta.dart';
import '../../../logd.dart';

/// Semantic tags describing the content of a [LogSegment].
enum LogTag {
  /// General metadata like timestamp, level, or logger name.
  header,

  /// Information about where the log was emitted (file, line, function).
  origin,

  /// The primary log message body.
  message,

  /// Error information (exception message).
  error,

  /// Individual frame in a stack trace.
  stackFrame,

  /// Content related to the log level (e.g. the "[[INFO]]" text).
  level,

  /// Content related to the timestamp.
  timestamp,

  /// Content related to the logger name.
  loggerName,

  /// Structural lines like box borders or dividers.
  border,

  /// Key in a JSON object.
  jsonKey,

  /// Value in a JSON object (string, number, boolean).
  jsonValue,

  /// Punctuation in JSON (braces, brackets, commas, colons).
  jsonPunctuation,

  /// Tree-like hierarchy prefix.
  hierarchy,

  /// Content Prefix
  prefix,
}

/// Visual style suggestion for a log segment.
@immutable
class TextStyle {
  /// Creates a [TextStyle].
  const TextStyle({
    this.color,
    this.bold,
    this.dim,
    this.italic,
    this.inverse,
  });

  /// The suggested foreground color.
  final LogColor? color;

  /// Whether the text should be bold.
  final bool? bold;

  /// Whether the text should be dimmed (faint).
  final bool? dim;

  /// Whether the text should be italic.
  final bool? italic;

  /// Whether the text should be inverted (reverse video).
  final bool? inverse;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is TextStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          bold == other.bold &&
          dim == other.dim &&
          italic == other.italic &&
          inverse == other.inverse;

  @override
  int get hashCode => Object.hash(color, bold, dim, italic, inverse);
}

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
    this.timestampColor,
    this.loggerNameColor,
    this.levelColor,
    this.borderColor,
    this.stackFrameColor,
    this.jsonKeyColor,
    this.jsonValueColor,
    this.jsonPunctuationColor,
  });

  // Base colors per level
  final LogColor trace;
  final LogColor debug;
  final LogColor info;
  final LogColor warning;
  final LogColor error;

  // Override colors for specific tags (optional)
  /// Color for timestamp segments. If null, uses base level color.
  final LogColor? timestampColor;

  /// Color for logger name segments. If null, uses base level color.
  final LogColor? loggerNameColor;

  /// Color for level indicator segments. If null, uses base level color.
  final LogColor? levelColor;

  /// Color for border segments. If null, uses base level color.
  final LogColor? borderColor;

  /// Color for stack frame segments. If null, uses base level color.
  final LogColor? stackFrameColor;

  /// Color for JSON key segments. If null, uses base level color.
  final LogColor? jsonKeyColor;

  /// Color for JSON value segments. If null, uses base level color.
  final LogColor? jsonValueColor;

  /// Color for JSON punctuation segments. If null, uses base level color.
  final LogColor? jsonPunctuationColor;

  /// Get color for a specific tag set at a given level.
  ///
  /// Priority: specific tag overrides > base level color.
  LogColor colorFor(final LogLevel level, final Set<LogTag> tags) {
    // Check for specific tag overrides first
    if (tags.contains(LogTag.timestamp) && timestampColor != null) {
      return timestampColor!;
    }
    if (tags.contains(LogTag.loggerName) && loggerNameColor != null) {
      return loggerNameColor!;
    }
    if (tags.contains(LogTag.level) && levelColor != null) {
      return levelColor!;
    }
    if (tags.contains(LogTag.border) && borderColor != null) {
      return borderColor!;
    }
    if (tags.contains(LogTag.stackFrame) && stackFrameColor != null) {
      return stackFrameColor!;
    }
    if (tags.contains(LogTag.jsonKey) && jsonKeyColor != null) {
      return jsonKeyColor!;
    }
    if (tags.contains(LogTag.jsonValue) && jsonValueColor != null) {
      return jsonValueColor!;
    }
    if (tags.contains(LogTag.jsonPunctuation) && jsonPunctuationColor != null) {
      return jsonPunctuationColor!;
    }

    // Fallback to base level color
    return colorForLevel(level);
  }

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
    jsonKeyColor: LogColor.brightBlue,
    jsonValueColor: LogColor.brightGreen,
    jsonPunctuationColor: LogColor.white,
  );

  static const darkScheme = ColorScheme(
    trace: LogColor.brightGreen,
    debug: LogColor.brightWhite,
    info: LogColor.brightBlue,
    warning: LogColor.brightYellow,
    error: LogColor.brightRed,
    jsonKeyColor: LogColor.brightCyan,
    jsonValueColor: LogColor.brightGreen,
    jsonPunctuationColor: LogColor.brightWhite,
  );

  /// Pastel theme scheme with softer colors.
  static const pastelScheme = ColorScheme(
    trace: LogColor.green,
    debug: LogColor.cyan,
    info: LogColor.brightCyan,
    warning: LogColor.brightYellow,
    error: LogColor.brightRed,
    jsonKeyColor: LogColor.cyan,
    jsonValueColor: LogColor.green,
    jsonPunctuationColor: LogColor.white,
  );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ColorScheme &&
          trace == other.trace &&
          debug == other.debug &&
          info == other.info &&
          warning == other.warning &&
          error == other.error &&
          timestampColor == other.timestampColor &&
          loggerNameColor == other.loggerNameColor &&
          levelColor == other.levelColor &&
          borderColor == other.borderColor &&
          stackFrameColor == other.stackFrameColor &&
          jsonKeyColor == other.jsonKeyColor &&
          jsonValueColor == other.jsonValueColor &&
          jsonPunctuationColor == other.jsonPunctuationColor;

  @override
  int get hashCode => Object.hash(
        trace,
        debug,
        info,
        warning,
        error,
        timestampColor,
        loggerNameColor,
        levelColor,
        borderColor,
        stackFrameColor,
        jsonKeyColor,
        jsonValueColor,
        jsonPunctuationColor,
      );
}

/// Configuration for fine-grained color application in [ColorDecorator].
@immutable
class ColorConfig {
  /// Creates a color application configuration.
  const ColorConfig({
    this.colorTimestamp = true,
    this.colorLevel = true,
    this.colorLoggerName = true,
    this.colorMessage = true,
    this.colorBorder = true,
    this.colorStackFrame = true,
    this.colorError = true,
    this.colorJson = true,
    this.colorHierarchy = false,
    this.headerBackground = false,
  });

  /// Whether to color timestamp segments.
  final bool colorTimestamp;

  /// Whether to color level indicator segments.
  final bool colorLevel;

  /// Whether to color logger name segments.
  final bool colorLoggerName;

  /// Whether to color message body segments.
  final bool colorMessage;

  /// Whether to color structural borders (e.g., box borders).
  final bool colorBorder;

  /// Whether to color stack trace frame segments.
  final bool colorStackFrame;

  /// Whether to color error information segments.
  final bool colorError;

  /// Whether to color JSON-specific segments.
  final bool colorJson;

  /// Whether to color hierarchical prefixes.
  final bool colorHierarchy;

  /// Whether to use inverse video (background color) for headers.
  final bool headerBackground;

  /// Determines if a segment with given tags should be colored.
  bool shouldColor(final Set<LogTag> tags) {
    if (tags.contains(LogTag.timestamp)) {
      return colorTimestamp;
    }
    if (tags.contains(LogTag.level)) {
      return colorLevel;
    }
    if (tags.contains(LogTag.loggerName)) {
      return colorLoggerName;
    }
    if (tags.contains(LogTag.message)) {
      return colorMessage;
    }
    if (tags.contains(LogTag.border)) {
      return colorBorder;
    }
    if (tags.contains(LogTag.stackFrame)) {
      return colorStackFrame;
    }
    if (tags.contains(LogTag.error)) {
      return colorError;
    }
    if (tags.contains(LogTag.jsonKey) ||
        tags.contains(LogTag.jsonValue) ||
        tags.contains(LogTag.jsonPunctuation)) {
      return colorJson;
    }
    if (tags.contains(LogTag.hierarchy)) {
      return colorHierarchy;
    }
    return true; // Default: color everything
  }

  /// Default configuration: color everything, no header background.
  static const all = ColorConfig();

  /// Minimal configuration: only color essential parts.
  static const minimal = ColorConfig(
    colorTimestamp: false,
    colorLoggerName: false,
    colorBorder: false,
  );

  /// Color everything except borders.
  static const noBorders = ColorConfig(
    colorBorder: false,
  );

  // Legacy compatibility methods
  @Deprecated('''
Use tag-specific controls instead.
Will be dropped in v0.5.0''')
  bool get colorHeader => colorTimestamp || colorLevel || colorLoggerName;

  @Deprecated('''
Use [colorMessage] instead.
Will be dropped in v0.5.0''')
  bool get colorBody => colorMessage;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ColorConfig &&
          colorTimestamp == other.colorTimestamp &&
          colorLevel == other.colorLevel &&
          colorLoggerName == other.colorLoggerName &&
          colorMessage == other.colorMessage &&
          colorBorder == other.colorBorder &&
          colorStackFrame == other.colorStackFrame &&
          colorError == other.colorError &&
          colorJson == other.colorJson &&
          colorHierarchy == other.colorHierarchy &&
          headerBackground == other.headerBackground;

  @override
  int get hashCode => Object.hash(
        colorTimestamp,
        colorLevel,
        colorLoggerName,
        colorMessage,
        colorBorder,
        colorStackFrame,
        colorError,
        colorJson,
        colorHierarchy,
        headerBackground,
      );
}
