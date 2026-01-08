part of '../handler.dart';

/// A sink that writes HTML-formatted logs to files.
///
/// Automatically wraps logs with complete HTML document structure including
/// embedded CSS for styling. Use with [HTMLFormatter] for styled HTML log files.
///
/// **Important**: Call [close()] when done logging to write the HTML footer.
///
/// Example:
/// ```dart
/// final sink = HTMLSink(filePath: 'logs/app.html');
/// final handler = Handler(
///   formatter: const HTMLFormatter(),
///   sink: sink,
/// );
/// // ... log entries ...
/// await sink.close(); // Write footer and close file
/// ```
final class HTMLSink extends LogSink {
  /// Creates an [HTMLSink].
  ///
  /// - [filePath]: Path to the HTML file to write to.
  /// - [darkMode]: Whether to use dark mode color scheme (default: true).
  HTMLSink({
    required this.filePath,
    this.darkMode = true,
  });

  /// Path to the HTML file.
  final String filePath;

  /// Whether to use dark mode styling.
  final bool darkMode;

  bool _headerWritten = false;
  bool _closed = false;

  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    if (_closed) {
      InternalLogger.log(
        LogLevel.warning,
        'HTMLSink is closed, cannot write logs',
      );
      return;
    }

    try {
      final file = io.File(filePath);

      // Write HTML header on first write
      if (!_headerWritten) {
        await file.writeAsString(_htmlHeader(), mode: io.FileMode.write);
        _headerWritten = true;
      }

      // Append log entries
      final buffer = StringBuffer();
      for (final line in lines) {
        for (final segment in line.segments) {
          buffer.write(segment.text);
        }
        buffer.writeln();
      }

      await file.writeAsString(buffer.toString(), mode: io.FileMode.append);
    } catch (e, s) {
      InternalLogger.log(
        LogLevel.error,
        'HTMLSink error writing to $filePath',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Closes the sink and writes the HTML footer.
  ///
  /// Should be called when done logging to complete the HTML document.
  Future<void> close() async {
    if (_closed) {
      return;
    }

    try {
      if (_headerWritten) {
        final file = io.File(filePath);
        await file.writeAsString(_htmlFooter(), mode: io.FileMode.append);
      }
      _closed = true;
    } catch (e, s) {
      InternalLogger.log(
        LogLevel.error,
        'HTMLSink error closing $filePath',
        error: e,
        stackTrace: s,
      );
    }
  }

  String _htmlHeader() => '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Log Output</title>
  <style>
${_css()}
  </style>
</head>
<body>
<div class="log-container">
''';

  String _htmlFooter() => '''
</div>
</body>
</html>
''';

  String _css() {
    final bg = darkMode ? '#1e1e1e' : '#ffffff';
    final fg = darkMode ? '#d4d4d4' : '#000000';
    final borderTrace = darkMode ? '#22c55e' : '#16a34a';
    final borderDebug = darkMode ? '#94a3b8' : '#64748b';
    final borderInfo = darkMode ? '#3b82f6' : '#2563eb';
    final borderWarning = darkMode ? '#f59e0b' : '#d97706';
    final borderError = darkMode ? '#ef4444' : '#dc2626';

    return '''
    body {
      background-color: $bg;
      color: $fg;
      font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
      padding: 1rem;
      line-height: 1.5;
    }
    .log-container {
      max-width: 1200px;
      margin: 0 auto;
    }
    .log-entry {
      margin-bottom: 1rem;
      padding: 0.75rem;
      border-radius: 6px;
      border-left: 4px solid;
      background-color: ${darkMode ? '#2d2d2d' : '#f8f9fa'};
    }
    .log-entry.log-trace { border-color: $borderTrace; }
    .log-entry.log-debug { border-color: $borderDebug; }
    .log-entry.log-info { border-color: $borderInfo; }
    .log-entry.log-warning { border-color: $borderWarning; }
    .log-entry.log-error { border-color: $borderError; }
    
    .log-header {
      font-weight: 600;
      margin-bottom: 0.5rem;
      display: flex;
      gap: 0.5rem;
      align-items: center;
    }
    .log-timestamp {
      opacity: 0.7;
      font-size: 0.9em;
    }
    .log-level {
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 0.85em;
      font-weight: bold;
      color: ${darkMode ? '#000' : '#fff'};
    }
   .log-entry.log-trace .log-level { background-color: $borderTrace; }
    .log-entry.log-debug .log-level { background- $borderDebug; }
    .log-entry.log-info .log-level { background-color: $borderInfo; }
    .log-entry.log-warning .log-level { background-color: $borderWarning; }
    .log-entry.log-error .log-level { background-color: $borderError; }
    
    .log-logger {
      opacity: 0.8;
      font-size: 0.9em;
      font-style: italic;
    }
    .log-origin {
      font-size: 0.85em;
      opacity: 0.7;
      margin-bottom: 0.25rem;
    }
    .log-message {
      margin: 0.5rem 0;
      white-space: pre-wrap;
      word-break: break-word;
    }
    .log-error {
      color: $borderError;
      font-weight: 600;
      margin-top: 0.5rem;
      padding: 0.5rem;
      background-color: ${darkMode ? '#3f1f1f' : '#fee2e2'};
      border-radius: 4px;
    }
    .log-stacktrace {
      font-size: 0.8em;
      opacity: 0.75;
      margin-top: 0.5rem;
      padding-left: 1rem;
      border-left: 2px solid ${darkMode ? '#4b5563' : '#d1d5db'};
    }
    .stack-frame {
      margin: 0.15rem 0;
      font-family: monospace;
    }
    ''';
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is HTMLSink &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          darkMode == other.darkMode;

  @override
  int get hashCode => Object.hash(filePath, darkMode);
}
