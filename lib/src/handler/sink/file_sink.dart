part of '../handler.dart';

/// Appends to a file.
// TODO: Make async for better performance.
// TODO: Add file rotation (e.g., size/time-based).
class FileSink implements LogSink {
  FileSink(
    this.path, {
    this.enabled = true,
  });

  /// Path to the log file (relative or absolute).
  final String path;

  @override
  final bool enabled;

  @override
  void output(final List<String> lines, final LogLevel level) {
    if (lines.isEmpty) {
      return;
    }

    final file = io.File(path);
    try {
      // Create parent directories if they don't exist.
      final parentDir = file.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }
      file.writeAsStringSync('${lines.join('\n')}\n', mode: io.FileMode.append);
    } catch (e) {
      // In debug mode, rethrow for easier debugging; in release, log to console.
      if (!const bool.fromEnvironment('dart.vm.product')) {
        rethrow;
      }
      print('FileSink error (path: $path): $e'); // Fallback output
    }
  }
}
