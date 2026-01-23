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

  /// Tree-like hierarchy prefix.
  hierarchy,

  /// Content Prefix
  prefix,
}

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

  /// Whether the text should be inverted (reverse video).
  final bool? inverse;

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
          inverse == other.inverse;

  @override
  int get hashCode =>
      Object.hash(color, backgroundColor, bold, dim, italic, inverse);
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

/// Defines a theme for logging, mapping semantic concepts to [LogStyle]s.
@immutable
class LogTheme {
  /// Creates a [LogTheme].
  ///
  /// [colorScheme] is required and defines the base palette.
  /// Optional style parameters allow overriding specific semantic segments.
  const LogTheme({
    required this.colorScheme,
    this.timestampStyle,
    this.loggerNameStyle,
    this.levelStyle,
    this.messageStyle,
    this.borderStyle,
    this.stackFrameStyle,
    this.errorStyle,
    this.hierarchyStyle,
  });

  /// The base color scheme for log levels.
  final LogColorScheme colorScheme;

  /// Style for timestamps.
  final LogStyle? timestampStyle;

  /// Style for logger names.
  final LogStyle? loggerNameStyle;

  /// Style for level indicators.
  final LogStyle? levelStyle;

  /// Style for the main message.
  final LogStyle? messageStyle;

  /// Style for borders/dividers.
  final LogStyle? borderStyle;

  /// Style for stack trace frames.
  final LogStyle? stackFrameStyle;

  /// Style for error messages.
  final LogStyle? errorStyle;

  /// Style for hierarchy lines.
  final LogStyle? hierarchyStyle;

  /// Resolves the style for a given segment based on level and tags.
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    // 1. Start with base color for the level
    // Exception: Hierarchy lines should NOT take level color by default.
    final baseColor = tags.contains(LogTag.hierarchy)
        ? null
        : colorScheme.colorForLevel(level);

    var style = LogStyle(color: baseColor);

    // 2. Apply default semantic styles
    if (tags.contains(LogTag.level)) {
      style = _merge(style, const LogStyle(bold: true));
    } else if (tags.contains(LogTag.timestamp) ||
        tags.contains(LogTag.loggerName)) {
      style = _merge(style, const LogStyle(dim: true));
    } else if (tags.contains(LogTag.header)) {
      style = _merge(style, const LogStyle(bold: true));
    }

    // 3. Apply tag-specific overrides/merges
    if (tags.contains(LogTag.level)) {
      style = _merge(style, levelStyle);
      // Ensure level color override from scheme
      // is respected if theme style doesn't enforce one
      if (colorScheme.levelColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.levelColor));
      }
    } else if (tags.contains(LogTag.timestamp)) {
      style = _merge(style, timestampStyle);
      if (colorScheme.timestampColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.timestampColor));
      }
    } else if (tags.contains(LogTag.loggerName)) {
      style = _merge(style, loggerNameStyle);
      if (colorScheme.loggerNameColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.loggerNameColor));
      }
    } else if (tags.contains(LogTag.message)) {
      style = _merge(style, messageStyle);
    } else if (tags.contains(LogTag.border)) {
      style = _merge(style, borderStyle);
      if (colorScheme.borderColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.borderColor));
      }
    } else if (tags.contains(LogTag.stackFrame)) {
      style = _merge(style, stackFrameStyle);
      if (colorScheme.stackFrameColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.stackFrameColor));
      }
    } else if (tags.contains(LogTag.error)) {
      style = _merge(style, errorStyle);
    } else if (tags.contains(LogTag.hierarchy)) {
      style = _merge(style, hierarchyStyle);
      if (colorScheme.hierarchyColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.hierarchyColor));
      }
    }

    return style;
  }

  LogStyle _merge(final LogStyle base, final LogStyle? override) {
    if (override == null) {
      return base;
    }
    return LogStyle(
      color: override.color ?? base.color,
      backgroundColor: override.backgroundColor ?? base.backgroundColor,
      bold: override.bold ?? base.bold,
      dim: override.dim ?? base.dim,
      italic: override.italic ?? base.italic,
      inverse: override.inverse ?? base.inverse,
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogTheme &&
          runtimeType == other.runtimeType &&
          colorScheme == other.colorScheme &&
          timestampStyle == other.timestampStyle &&
          loggerNameStyle == other.loggerNameStyle &&
          levelStyle == other.levelStyle &&
          messageStyle == other.messageStyle &&
          borderStyle == other.borderStyle &&
          stackFrameStyle == other.stackFrameStyle &&
          errorStyle == other.errorStyle &&
          hierarchyStyle == other.hierarchyStyle;

  @override
  int get hashCode => Object.hash(
        colorScheme,
        timestampStyle,
        loggerNameStyle,
        levelStyle,
        messageStyle,
        borderStyle,
        stackFrameStyle,
        errorStyle,
        hierarchyStyle,
      );
}
