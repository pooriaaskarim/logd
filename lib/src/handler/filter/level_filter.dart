part of '../handler.dart';

/// Filters entries below a minimum level.
class LevelFilter implements LogFilter {
  const LevelFilter(this.minimumLevel);

  /// The minimum level to allow (inclusive).
  final LogLevel minimumLevel;

  @override
  bool shouldLog(final LogEntry entry) =>
      entry.level.index >= minimumLevel.index;
}
