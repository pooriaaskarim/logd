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
    switch (node) {
      case BoxNode():
        _renderBox(buffer, node);
      case IndentationNode():
        _renderIndentation(buffer, node);
      case DecoratedNode():
        _renderDecorated(buffer, node);
      case RowNode():
        _renderRow(buffer, node);
      case FillerNode():
        _renderFiller(buffer);
      case ParagraphNode():
        _renderContainer(buffer, node.children, node.tags, 'p');
      case GroupNode():
        _renderContainer(buffer, node.children, node.tags, 'div');
      case MapNode():
        buffer.write('<pre class="log-line log-map">');
        buffer.write(_escapeHtml(node.toString()));
        buffer.writeln('</pre>');
      case ListNode():
        buffer.write('<pre class="log-line log-list">');
        buffer.write(_escapeHtml(node.toString()));
        buffer.writeln('</pre>');
      case ContentNode():
        buffer.write('<p class="log-line">');
        _renderContent(buffer, node);
        buffer.writeln('</p>');
    }
  }

  void _renderBox(final StringBuffer buffer, final BoxNode node) {
    buffer.write('<fieldset class="log-box">');
    if (node.title != null) {
      final titleClasses = _getClasses(node.title!.tags, isContainer: false);
      buffer.write('<legend');
      if (titleClasses.isNotEmpty) {
        buffer.write(' class="$titleClasses"');
      }
      buffer.write('>${_escapeHtml(node.title!.text)}</legend>');
    }
    for (final child in node.children) {
      _renderNode(buffer, child);
    }
    buffer.writeln('</fieldset>');
  }

  void _renderIndentation(
    final StringBuffer buffer,
    final IndentationNode node,
  ) {
    buffer.write('<blockquote class="log-indent">');
    for (final child in node.children) {
      _renderNode(buffer, child);
    }
    buffer.writeln('</blockquote>');
  }

  void _renderDecorated(final StringBuffer buffer, final DecoratedNode node) {
    buffer.write('<div class="log-decorated">');
    final leading = node.leading;
    if (leading != null && leading.isNotEmpty) {
      buffer.write('<span class="log-leading" aria-hidden="true">');
      for (final segment in leading) {
        final classes = _getClasses(segment.tags, isContainer: false);
        final text = _escapeHtml(segment.text);
        if (classes.isNotEmpty) {
          buffer.write('<span class="$classes">$text</span>');
        } else {
          buffer.write(text);
        }
      }
      buffer.write('</span>');
    }
    buffer.write('<div class="log-decorated-content">');
    for (final child in node.children) {
      _renderNode(buffer, child);
    }
    buffer
      ..writeln('</div>')
      ..writeln('</div>');
  }

  void _renderRow(final StringBuffer buffer, final RowNode node) {
    buffer.write('<div class="log-row">');
    for (final child in node.children) {
      buffer.write('<span class="log-row-cell">');
      _renderNode(buffer, child);
      buffer.write('</span>');
    }
    buffer.writeln('</div>');
  }

  void _renderFiller(final StringBuffer buffer) {
    buffer.writeln('<hr class="log-filler" aria-hidden="true">');
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
    /* --- Layout node elements --- */
    fieldset.log-box {
      border: 1px solid ${darkMode ? '#4b5563' : '#d1d5db'};
      border-radius: 4px;
      padding: 0.5rem 0.75rem;
      margin: 0.25rem 0;
    }
    fieldset.log-box legend {
      font-size: 0.85em;
      font-weight: 600;
      padding: 0 0.25rem;
      opacity: 0.8;
    }
    blockquote.log-indent {
      margin: 0.1rem 0 0.1rem 1.5rem;
      padding: 0;
      border-left: 2px solid ${darkMode ? '#4b5563' : '#d1d5db'};
      padding-left: 0.5rem;
    }
    .log-decorated {
      display: flex;
      gap: 0.25rem;
      align-items: flex-start;
    }
    .log-leading {
      flex-shrink: 0;
      opacity: 0.6;
      font-family: monospace;
      font-size: 0.9em;
    }
    .log-decorated-content {
      flex: 1;
    }
    .log-row {
      display: flex;
      flex-wrap: wrap;
      gap: 0.25rem;
      align-items: baseline;
    }
    .log-row-cell {
      display: inline-block;
    }
    hr.log-filler {
      border: none;
      border-top: 1px solid ${darkMode ? '#4b5563' : '#d1d5db'};
      margin: 0.25rem 0;
    }
    p.log-line {
      margin: 0.1rem 0;
      white-space: pre-wrap;
      word-break: break-word;
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
