part of '../handler.dart';

/// Appends to a file.
//todo: Async needed
//todo: File rotation needed
class FileSink implements LogSink {
  FileSink(
    this.path, {
    this.enabled = true,
  });

  /// Path to the log file.
  final String path;
  @override
  final bool enabled;
  @override
  void output(final List<String> lines, final LogLevel level) {
    final file = io.File(path);
    try {
      file.writeAsStringSync('${lines.join('\n')}\n', mode: io.FileMode.append);
    } catch (e) {
      // Swallow error to avoid app crash; perhaps log to console.
      debugPrint('FileSink error: $e');
    }
  }
}
