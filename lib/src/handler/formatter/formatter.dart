part of '../handler.dart';

/// Abstract base for formatting a [LogEntry] into lines of text.
//ignore: one_member_abstracts
abstract class LogFormatter {
  const LogFormatter();

  /// Format the entry into lines (e.g., for boxed or JSON).
  List<String> format(final LogEntry entry);
}
