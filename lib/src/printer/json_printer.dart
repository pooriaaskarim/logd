import 'dart:convert';
import '../logger/logger.dart';
import 'printer.dart';

/// Prints logs as JSON lines — perfect for log aggregation tools.
class JsonPrinter extends Printer {
  @override
  List<String> format(final LogEntry entry) {
    final map = {
      'time': entry.timestamp,
      'level': entry.level.name.toUpperCase(),
      'origin': entry.origin,
      'message': entry.message,
      if (entry.error != null) 'error': entry.error.toString(),
      if (entry.stackTrace != null) 'stack': entry.stackTrace.toString(),
    };
    return [jsonEncode(map)];
  }
}
