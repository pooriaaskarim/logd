part of '../handler.dart';

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
class LogColorScheme {
  /// Creates a color scheme.
  const LogColorScheme({
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
    this.hierarchyColor,
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

  /// Color for hierarchy lines. If null, defaults to null (no color).
  final LogColor? hierarchyColor;

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
    if (tags.contains(LogTag.hierarchy) && hierarchyColor != null) {
      return hierarchyColor!;
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

  static const defaultScheme = LogColorScheme(
    trace: LogColor.green,
    debug: LogColor.white,
    info: LogColor.blue,
    warning: LogColor.yellow,
    error: LogColor.red,
  );

  static const darkScheme = LogColorScheme(
    trace: LogColor.brightGreen,
    debug: LogColor.brightWhite,
    info: LogColor.brightBlue,
    warning: LogColor.brightYellow,
    error: LogColor.brightRed,
  );

  static const pastelScheme = LogColorScheme(
    trace: LogColor.green,
    debug: LogColor.cyan,
    info: LogColor.brightCyan,
    warning: LogColor.brightYellow,
    error: LogColor.brightRed,
  );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogColorScheme &&
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
          hierarchyColor == other.hierarchyColor;

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
        hierarchyColor,
      );
}
