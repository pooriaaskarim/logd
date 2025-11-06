import 'package:flutter/foundation.dart';

import '../logger/logger.dart';

/// Abstract base class for all log printers.
///
/// A printer has two responsibilities:
/// 1. Format a [LogEntry] into lines of text
/// 2. Output those lines (console, file, network, etc.)
///
/// You can extend this to create:
/// - Pretty console printers
/// - JSON printers
/// - File printers
/// - Remote loggers
/// - Silent printers
abstract class Printer {
  /// Minimum level this printer accepts. Override for per-printer filtering.
  LogLevel get minLevel => LogLevel.trace;

  /// Format the log entry into a list of strings (one per line).
  List<String> format(final LogEntry entry);

  /// Output the formatted lines.
  /// Default: uses `debugPrint` (safe for Flutter).
  void output(final List<String> lines, final LogLevel level) {
    for (final line in lines) {
      debugPrint(line);
    }
    debugPrint(''); // extra newline
  }

  /// Full log pipeline. Called by [Logger].
  /// Filters by [minLevel] before formatting.
  void log(final LogEntry entry) {
    if (entry.level.index < minLevel.index) {
      return;
    }
    final lines = format(entry);
    if (lines.isNotEmpty) {
      output(lines, entry.level);
    }
  }
}
