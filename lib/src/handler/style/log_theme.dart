part of '../handler.dart';

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

  /// Resolves the visual style for a [LogNode] based on its tags and log level.
  ///
  /// This is used for layout nodes (like [BoxNode]) to determine border or
  /// container styling from semantic tags.
  LogStyle resolveNodeStyle(final LogNode node, final LogLevel level) {
    if (node.tags.isEmpty) {
      return LogStyle(color: colorScheme.colorForLevel(level));
    }
    return getStyle(level, node.tags);
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
