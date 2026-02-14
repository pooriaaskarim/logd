part of '../handler.dart';

/// Abstract base for filtering log entries before processing.
//ignore: one_member_abstracts
abstract class LogFilter {
  const LogFilter();

  /// Returns true if the entry should be logged, false to drop it.
  bool shouldLog(final LogEntry entry);
}
