part of '../handler.dart';

/// An encoder that transforms [LogDocument] into HTML markup.
///
/// It traverses the semantic tree and renders nodes as HTML elements, applying
/// CSS classes based on [LogTag]s.
@immutable
class HtmlEncoder implements LogEncoder<String> {
  /// Creates an [HtmlEncoder].
  ///
  /// - [darkMode]: Whether to use dark mode color scheme (default: true).
  const HtmlEncoder({
    this.darkMode = true,
  });

  /// Whether to use dark mode styling.
  final bool darkMode;

  @override
  String preamble(final LogLevel level, {final LogDocument? document}) => '''
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

  @override
  String postamble(final LogLevel level) => '''
</div>
</body>
</html>
''';

  @override
  String encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level, {
    final int? width,
  }) {
    final buffer = StringBuffer()

      // Root entry container
      ..writeln('<div class="log-entry log-${level.name}">');

    for (final node in document.nodes) {
      _renderNode(buffer, node);
    }

    buffer.writeln('</div>');
    return buffer.toString();
  }

  void _renderNode(final StringBuffer buffer, final LogNode node) {
    if (node is ParagraphNode) {
      _renderContainer(buffer, node.children, node.tags, 'div');
    } else if (node is GroupNode) {
      _renderContainer(buffer, node.children, node.tags, 'div');
    } else if (node is IndentationNode) {
      for (final child in node.children) {
        _renderNode(buffer, child);
      }
    } else if (node is DecoratedNode) {
      for (final child in node.children) {
        _renderNode(buffer, child);
      }
    } else if (node is ContentNode) {
      _renderContent(buffer, node);
    }
  }

  void _renderContainer(
    final StringBuffer buffer,
    final List<LogNode> children,
    final Set<LogTag> tags,
    final String tagName,
  ) {
    final classes = _getClasses(tags, isContainer: true);
    if (classes.isNotEmpty) {
      buffer.write('<$tagName class="$classes">');
    } else {
      buffer.write('<$tagName>');
    }

    for (final child in children) {
      _renderNode(buffer, child);
    }

    buffer.writeln('</$tagName>');
  }

  void _renderContent(final StringBuffer buffer, final ContentNode node) {
    for (final segment in node.segments) {
      final classes = _getClasses(segment.tags, isContainer: false);
      final text = _escapeHtml(segment.text);
      if (classes.isNotEmpty) {
        buffer.write('<span class="$classes">$text</span>');
      } else {
        buffer.write(text);
      }
    }
  }

  String _getClasses(
    final Set<LogTag> tags, {
    required final bool isContainer,
  }) {
    final classes = <String>[];
    if (tags.contains(LogTag.header)) {
      classes.add('log-header');
    }
    if (tags.contains(LogTag.timestamp)) {
      classes.add('log-timestamp');
    }
    if (tags.contains(LogTag.level)) {
      classes.add('log-level');
    }
    if (tags.contains(LogTag.loggerName)) {
      classes.add('log-logger');
    }
    if (tags.contains(LogTag.origin)) {
      classes.add('log-origin');
    }
    if (tags.contains(LogTag.message)) {
      classes.add('log-message');
    }
    if (tags.contains(LogTag.error)) {
      classes.add('log-error');
    }

    if (tags.contains(LogTag.stackFrame)) {
      if (tags.contains(LogTag.hierarchy)) {
        classes.add('log-stacktrace');
      } else {
        classes.add('stack-frame');
      }
    }

    return classes.join(' ');
  }

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
    .log-entry.log-debug .log-level { background-color: $borderDebug; }
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

  String _escapeHtml(final String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
