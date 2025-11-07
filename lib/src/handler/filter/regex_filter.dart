part of '../handler.dart';

/// Filter log entry on message regex match.
class RegexFilter implements LogFilter {
  const RegexFilter(this.regex, {this.invert = false});

  /// The regex to match against the message.
  final RegExp regex;

  /// If true, invert the match (drop if matches).
  final bool invert;

  @override
  bool shouldLog(final LogEntry entry) {
    final match = regex.hasMatch(entry.message);
    return invert ? !match : match;
  }
}
