part of '../handler.dart';

/// Encodes logs as HTML5 fragments (`<details>` blocks) with embedded styles.
///
/// This encoder translates semantic tags (like [LogTag.border] and
/// [LogTag.hierarchy])
/// into CSS properties, allowing decorators to influence the HTML presentation.
class HtmlEncoder implements LogEncoder<String> {
  /// Creates an [HtmlEncoder].
  ///
  /// - [darkMode]: Whether to generate colors optimized for dark backgrounds.
  /// - [theme]: Optional theme to resolve semantic tags into styles.
  const HtmlEncoder({this.darkMode = true, this.theme});

  /// Whether to use dark mode styling.
  final bool darkMode;

  /// The theme used to resolve styles from semantic tags.
  final LogTheme? theme;

  @override
  String encode(final LogDocument document, final LogLevel level) {
    if (document.nodes.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    for (final node in document.nodes) {
      _renderNode(node, level, buffer);
    }
    return buffer.toString().trimRight();
  }

  void _renderNode(
    final LogNode node,
    final LogLevel level,
    final StringBuffer buffer,
  ) {
    switch (node) {
      case final HeaderNode s:
        buffer.write('<summary>');
        _writeSegments(buffer, s.segments, level);
        buffer.writeln('</summary>');
      case final ContentNode s:
        final className = switch (s) {
          ErrorNode _ => ' class="log-line log-error"',
          MetadataNode _ => ' class="log-line log-metadata"',
          _ => ' class="log-line"',
        };
        buffer.write('<div$className>');
        _writeSegments(buffer, s.segments, level);
        buffer.writeln('</div>');
      case final BoxNode c:
        buffer.writeln('<details class="log-entry log-${level.name}" open>');
        if (c.title != null) {
          buffer.writeln('<summary class="log-title">${c.title}</summary>');
        }
        for (final child in c.children) {
          _renderNode(child, level, buffer);
        }
        buffer.writeln('</details>');
      case final IndentationNode c:
        buffer.writeln('<div class="log-hierarchy-container">');
        for (final child in c.children) {
          _renderNode(child, level, buffer);
        }
        buffer.writeln('</div>');
      case final DecoratedNode c:
        // Use CSS for decoration instead of literal characters
        final cssClass = c.leadingHint ?? 'decorated';
        buffer.write('<div class="$cssClass">');
        for (final child in c.children) {
          _renderNode(child, level, buffer);
        }
        buffer.writeln('</div>');
      case final GroupNode c:
        for (final child in c.children) {
          _renderNode(child, level, buffer);
        }
    }
  }

  void _writeSegments(
    final StringBuffer buffer,
    final List<StyledText> segments,
    final LogLevel level,
  ) {
    for (final segment in segments) {
      final classes = _getClasses(segment);
      final style = segment.style ?? theme?.getStyle(level, segment.tags);
      final inlineStyle = _styleToCss(style);
      final escapedText = _escapeHtml(segment.text);

      if (classes.isNotEmpty || inlineStyle.isNotEmpty) {
        buffer.write('<span');
        if (classes.isNotEmpty) {
          buffer.write(' class="$classes"');
        }
        if (inlineStyle.isNotEmpty) {
          buffer.write(' style="$inlineStyle"');
        }
        buffer.write('>$escapedText</span>');
      } else {
        buffer.write(escapedText);
      }
    }
  }

  String _getClasses(final StyledText segment) {
    final classes = <String>[];
    if (segment.tags.contains(LogTag.header)) {
      classes.add('log-header');
    }
    if (segment.tags.contains(LogTag.timestamp)) {
      classes.add('log-timestamp');
    }
    if (segment.tags.contains(LogTag.level)) {
      classes.add('log-level');
    }
    if (segment.tags.contains(LogTag.loggerName)) {
      classes.add('log-logger');
    }
    if (segment.tags.contains(LogTag.message)) {
      classes.add('log-message');
    }
    if (segment.tags.contains(LogTag.error)) {
      classes.add('log-error');
    }
    if (segment.tags.contains(LogTag.stackFrame)) {
      classes.add('log-stackframe');
    }
    if (segment.tags.contains(LogTag.origin)) {
      classes.add('log-origin');
    }
    if (segment.tags.contains(LogTag.hierarchy)) {
      classes.add('log-hierarchy');
    }

    return classes.join(' ');
  }

  String _styleToCss(final LogStyle? style) {
    if (style == null) {
      return '';
    }
    final buffer = StringBuffer();

    if (style.color != null) {
      buffer.write('color: ${_colorToCss(style.color!)};');
    }
    if (style.backgroundColor != null) {
      buffer.write('background-color: ${_colorToCss(style.backgroundColor!)};');
    }
    if (style.bold == true) {
      buffer.write('font-weight: bold;');
    }
    if (style.dim == true) {
      buffer.write('opacity: 0.6;');
    }
    if (style.italic == true) {
      buffer.write('font-style: italic;');
    }
    return buffer.toString();
  }

  String _colorToCss(final LogColor color) {
    switch (color) {
      case LogColor.black:
        return '#000000';
      case LogColor.red:
        return '#cd3131';
      case LogColor.green:
        return '#0dbc79';
      case LogColor.yellow:
        return '#e5e510';
      case LogColor.blue:
        return '#2472c8';
      case LogColor.magenta:
        return '#bc3fbc';
      case LogColor.cyan:
        return '#11a8cd';
      case LogColor.white:
        return '#e5e5e5';
      case LogColor.brightBlack:
        return '#666666';
      case LogColor.brightRed:
        return '#f14c4c';
      case LogColor.brightGreen:
        return '#23d18b';
      case LogColor.brightYellow:
        return '#f5f543';
      case LogColor.brightBlue:
        return '#3b8eea';
      case LogColor.brightMagenta:
        return '#d670d6';
      case LogColor.brightCyan:
        return '#29b8db';
      case LogColor.brightWhite:
        return '#ffffff';
    }
  }

  /// Escapes HTML special characters.
  String _escapeHtml(final String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  /// Generates the CSS styles required for the HTML output.
  String get css {
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
      line-height: 1.2;
    }
    /* Container */
    .log-container {
      max-width: 100%;
      margin: 0 auto;
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }

    /* Details Box */
    details.log-entry {
      border-radius: 6px;
      background-color: ${darkMode ? '#2d2d2d' : '#f8f9fa'};
      border: 1px solid ${darkMode ? '#3e3e3e' : '#e5e7eb'};
      border-left: 4px solid;
      overflow: hidden;
      transition: all 0.2s;
    }
    details.log-entry[open] {
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    }

    details.log-entry.log-trace { border-left-color: $borderTrace; }
    details.log-entry.log-debug { border-left-color: $borderDebug; }
    details.log-entry.log-info { border-left-color: $borderInfo; }
    details.log-entry.log-warning { border-left-color: $borderWarning; }
    details.log-entry.log-error { border-left-color: $borderError; }

    /* Summary Header */
    summary {
      padding: 0.5rem 0.75rem;
      cursor: pointer;
      user-select: none;
      font-weight: 500;
      white-space: pre-wrap;
      list-style: none; /* Hide default triangle in some browsers */
      display: flex;
      align-items: center; /* Align items vertically */
    }
    summary::-webkit-details-marker {
      display: none; /* Hide default triangle in Chrome/Safari */
    }
    summary:hover {
      background-color: ${darkMode ? '#363636' : '#edf2f7'};
    }
    
    /* Custom Disclosure Indicator */
    summary::before {
      content: '▶';
      font-size: 0.8em;
      margin-right: 0.6em;
      transition: transform 0.2s;
      opacity: 0.5;
    }
    details[open] > summary::before {
      transform: rotate(90deg);
    }

    /* Body Content */
    .log-body {
      padding: 0.5rem 0.75rem 0.75rem 0.75rem;
      border-top: 1px solid ${darkMode ? '#3e3e3e' : '#e5e7eb'};
      background-color: ${darkMode ? '#262626' : '#ffffff'};
      white-space: pre-wrap;
      overflow-x: auto;
    }
    
    .log-line {
      min-height: 1.2em;
    }

    /* Semantic Styles */
    .log-header { font-weight: bold; }
    .log-timestamp { opacity: 0.6; color: ${darkMode ? '#888' : '#666'}; }
    .log-level { font-weight: bold; }
    
    .log-entry.log-trace .log-level { color: $borderTrace; }
    .log-entry.log-debug .log-level { color: $borderDebug; }
    .log-entry.log-info .log-level { color: $borderInfo; }
    .log-entry.log-warning .log-level { color: $borderWarning; }
    .log-entry.log-error .log-level { color: $borderError; }

    .log-logger {
      opacity: 0.8;
      font-style: italic;
      color: ${darkMode ? '#4ec9b0' : '#267f99'};
    }
    
    .log-origin { opacity: 0.5; font-size: 0.9em; }
    .log-error { color: $borderError; font-weight: bold; }
    .log-stackframe { opacity: 0.7; font-size: 0.9em; color: ${darkMode ? '#9cdcfe' : '#001080'}; }
    .log-hierarchy { opacity: 0.3; }
    ''';
  }
}
