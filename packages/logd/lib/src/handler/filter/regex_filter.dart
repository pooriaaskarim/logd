part of '../handler.dart';

/// Filter log entry on message regex match.
@immutable
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

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is RegexFilter &&
          runtimeType == other.runtimeType &&
          regex.pattern == other.regex.pattern &&
          regex.isCaseSensitive == other.regex.isCaseSensitive &&
          regex.isMultiLine == other.regex.isMultiLine &&
          regex.isUnicode == other.regex.isUnicode &&
          regex.isDotAll == other.regex.isDotAll &&
          invert == other.invert;

  @override
  int get hashCode => Object.hash(
        regex.pattern,
        regex.isCaseSensitive,
        regex.isMultiLine,
        regex.isUnicode,
        regex.isDotAll,
        invert,
      );
}
