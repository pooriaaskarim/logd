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
    this.title = 'Log Output',
  });

  /// Whether to use dark mode styling.
  final bool darkMode;

  /// The title of the generated HTML document.
  final String title;

  @override
  String preamble(final LogLevel level, {final LogDocument? document}) {
    final title = _escapeHtml(this.title);
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
${_css()}
  </style>
</head>
<body>
<div class="log-container">
''';
  }

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
        _renderFiller(buffer, node);
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
    final borderClass = switch (node.border) {
      BoxBorderStyle.rounded => 'log-box log-box-rounded',
      BoxBorderStyle.sharp => 'log-box log-box-sharp',
      BoxBorderStyle.double => 'log-box log-box-double',
      BoxBorderStyle.none => 'log-box log-box-none',
    };
    final styleAttr = _styleAttr(node.style);
    buffer.write('<fieldset class="$borderClass"$styleAttr>');
    if (node.title != null) {
      final titleClasses = _getClasses(node.title!.tags);
      final titleStyle = _styleAttr(node.title!.style);
      buffer.write('<legend');
      if (titleClasses.isNotEmpty) {
        buffer.write(' class="$titleClasses"');
      }
      buffer.write('$titleStyle>${_escapeHtml(node.title!.text)}</legend>');
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
    final styleAttr = _styleAttr(node.style);
    buffer.write('<div class="log-indent"$styleAttr>');
    for (final child in node.children) {
      _renderNode(buffer, child);
    }
    buffer.writeln('</div>');
  }

  void _renderDecorated(final StringBuffer buffer, final DecoratedNode node) {
    final styleAttr = _styleAttr(node.style);
    buffer.write('<div class="log-decorated"$styleAttr>');

    // Leading decoration (e.g. prefix, JSON key, border char)
    final leading = node.leading;
    if (leading != null && leading.isNotEmpty) {
      buffer.write('<span class="log-leading" aria-hidden="true">');
      for (final segment in leading) {
        _renderStyledText(buffer, segment);
      }
      buffer.write('</span>');
    }

    // Main content
    buffer.write('<div class="log-decorated-content">');
    for (final child in node.children) {
      _renderNode(buffer, child);
    }
    buffer.writeln('</div>');

    // Trailing decoration (e.g. suffix from SuffixDecorator)
    final trailing = node.trailing;
    if (trailing != null && trailing.isNotEmpty) {
      buffer.write('<span class="log-trailing" aria-hidden="true">');
      for (final segment in trailing) {
        _renderStyledText(buffer, segment);
      }
      buffer.write('</span>');
    }

    buffer.writeln('</div>');
  }

  void _renderRow(final StringBuffer buffer, final RowNode node) {
    buffer.write('<div class="log-row">');
    for (final child in node.children) {
      buffer.write('<div class="log-row-cell">');
      _renderNode(buffer, child);
      buffer.write('</div>');
    }
    buffer.writeln('</div>');
  }

  void _renderFiller(final StringBuffer buffer, final FillerNode node) {
    final styleAttr = _styleAttr(node.style);
    buffer.writeln('<hr class="log-filler" aria-hidden="true"$styleAttr>');
  }

  void _renderContainer(
    final StringBuffer buffer,
    final List<LogNode> children,
    final int tags,
    final String tagName,
  ) {
    final classes = _getClasses(tags);
    buffer.write('<$tagName');
    if (classes.isNotEmpty) {
      buffer.write(' class="$classes"');
    }
    buffer.write('>');

    for (final child in children) {
      _renderNode(buffer, child);
    }

    buffer.writeln('</$tagName>');
  }

  void _renderContent(final StringBuffer buffer, final ContentNode node) {
    for (final segment in node.segments) {
      _renderStyledText(buffer, segment);
    }
  }

  /// Renders a single [StyledText] segment, applying both semantic CSS classes
  /// and inline styles from [LogStyle].
  void _renderStyledText(final StringBuffer buffer, final StyledText segment) {
    final classes = _getClasses(segment.tags);
    final styleAttr = _styleAttr(segment.style, tags: segment.tags);
    final text = _escapeHtml(segment.text);
    if (classes.isNotEmpty || styleAttr.isNotEmpty) {
      buffer.write('<span');
      if (classes.isNotEmpty) {
        buffer.write(' class="$classes"');
      }
      buffer.write('$styleAttr>$text</span>');
    } else {
      buffer.write(text);
    }
  }

  String _getClasses(final int tags) {
    final classes = <String>[];
    if ((tags & LogTag.header) != 0) {
      classes.add('log-header');
    }
    if ((tags & LogTag.timestamp) != 0) {
      classes.add('log-timestamp');
    }
    if ((tags & LogTag.level) != 0) {
      classes.add('log-level');
    }
    if ((tags & LogTag.loggerName) != 0) {
      classes.add('log-logger');
    }
    if ((tags & LogTag.origin) != 0) {
      classes.add('log-origin');
    }
    if ((tags & LogTag.message) != 0) {
      classes.add('log-message');
    }
    if ((tags & LogTag.error) != 0) {
      classes.add('log-error');
    }
    if ((tags & LogTag.border) != 0) {
      classes.add('log-border');
    }
    if ((tags & LogTag.hierarchy) != 0) {
      classes.add('log-hierarchy');
    }
    if ((tags & LogTag.prefix) != 0) {
      classes.add('log-prefix');
    }
    if ((tags & LogTag.suffix) != 0) {
      classes.add('log-suffix');
    }
    if ((tags & LogTag.key) != 0) {
      classes.add('log-key');
    }
    if ((tags & LogTag.value) != 0) {
      classes.add('log-val');
    }
    if ((tags & LogTag.punctuation) != 0) {
      classes.add('log-punct');
    }
    if ((tags & LogTag.collapsible) != 0) {
      classes.add('log-collapsible');
    }

    if ((tags & LogTag.stackFrame) != 0) {
      if ((tags & LogTag.hierarchy) != 0) {
        classes.add('log-stacktrace');
      } else {
        classes.add('stack-frame');
      }
    }

    return classes.join(' ');
  }

  /// Converts a [LogStyle] to an inline HTML style attribute string.
  /// Returns an empty string if the style is null or has no properties.
  String _styleAttr(final LogStyle? style, {final int? tags}) {
    if (style == null) {
      return '';
    }
    final parts = <String>[];
    if (style.color != null) {
      // Avoid overriding badge foreground with level theme color
      // Also avoid overriding JSON key/value colors which are handled by CSS classes
      if (tags == null ||
          !((tags & LogTag.level) != 0 ||
              (tags & LogTag.key) != 0 ||
              (tags & LogTag.value) != 0)) {
        parts.add('color:${_cssColor(style.color!)}');
      }
    }
    if (style.backgroundColor != null) {
      parts.add('background-color:${_cssColor(style.backgroundColor!)}');
    }
    if (style.bold == true) {
      parts.add('font-weight:700');
    }
    if (style.italic == true) {
      parts.add('font-style:italic');
    }
    if (style.dim == true) {
      parts.add('opacity:0.5');
    }
    if (style.underline == true) {
      parts.add('text-decoration:underline');
    }
    if (style.inverse == true) {
      parts.add('filter:invert(1)');
    }
    if (parts.isEmpty) {
      return '';
    }
    return ' style="${parts.join(';')}"';
  }

  static const _colorMap = <LogColor, String>{
    LogColor.black: '#000000',
    LogColor.red: '#ef4444',
    LogColor.green: '#22c55e',
    LogColor.yellow: '#eab308',
    LogColor.blue: '#3b82f6',
    LogColor.magenta: '#a855f7',
    LogColor.cyan: '#06b6d4',
    LogColor.white: '#f1f5f9',
    LogColor.brightBlack: '#374151',
    LogColor.brightRed: '#f87171',
    LogColor.brightGreen: '#4ade80',
    LogColor.brightYellow: '#fde047',
    LogColor.brightBlue: '#60a5fa',
    LogColor.brightMagenta: '#c084fc',
    LogColor.brightCyan: '#22d3ee',
    LogColor.brightWhite: '#f8fafc',
  };

  String _cssColor(final LogColor color) => _colorMap[color] ?? 'inherit';

  String _css() {
    final bg = darkMode ? '#1e1e1e' : '#ffffff';
    final fg = darkMode ? '#d4d4d4' : '#000000';
    final borderTrace = darkMode ? '#22c55e' : '#16a34a';
    final borderDebug = darkMode ? '#94a3b8' : '#64748b';
    final borderInfo = darkMode ? '#3b82f6' : '#2563eb';
    final borderWarning = darkMode ? '#f59e0b' : '#d97706';
    final borderError = darkMode ? '#ef4444' : '#dc2626';

    return """
    * { box-sizing: border-box; }
    body {
      background-color: $bg;
      color: $fg;
      font-family: 'Fira Code', 'SFMono-Regular', Consolas, 'Courier New', monospace;
      font-size: 13px;
      padding: 1.5rem;
      line-height: 1.5;
      margin: 0;
    }
    .log-container { max-width: 1200px; margin: 0 auto; }

    /* === Entry === */
    .log-entry {
      margin-bottom: 0.25rem;
      padding: 0.6rem 0.5rem;
      border-bottom: 1px solid ${darkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)'};
      transition: background-color 0.15s ease;
    }
    .log-entry:hover {
      background-color: ${darkMode ? 'rgba(255,255,255,0.02)' : 'rgba(0,0,0,0.02)'};
    }

    /* === Metadata === */
    .log-header {
      font-weight: 600;
      margin-bottom: 0.35rem;
      display: flex;
      flex-wrap: wrap;
      gap: 0.6rem;
      align-items: center;
    }
    .log-timestamp { opacity: 0.75; font-size: 11px; font-weight: 400; letter-spacing: 0.3px; }
    .log-level {
      padding: 1px 5px;
      border-radius: 3px;
      font-size: 10px;
      font-weight: 800;
      letter-spacing: 0.6px;
      color: #0f0f0f !important; /* Fixed foreground for badge */
      text-transform: uppercase;
    }
    .log-entry.log-trace .log-level   { background-color: $borderTrace; }
    .log-entry.log-debug .log-level   { background-color: $borderDebug; }
    .log-entry.log-info .log-level    { background-color: $borderInfo; }
    .log-entry.log-warning .log-level { background-color: $borderWarning; }
    .log-entry.log-error .log-level   { background-color: $borderError; }
    .log-logger { opacity: 0.75; font-style: italic; font-size: 12px; }
    .log-origin { font-size: 11px; opacity: 0.45; margin-bottom: 0.15rem; }

    /* === Content === */
    .log-message { margin: 0.15rem 0; white-space: pre-wrap; word-break: break-word; }
    .log-error {
      color: $borderError;
      font-weight: 600;
      margin-top: 0.4rem;
      padding: 0.4rem 0.6rem;
      background-color: ${darkMode ? 'rgba(239,68,68,0.08)' : 'rgba(220,38,38,0.05)'};
      border-radius: 3px;
      border-left: 2px solid $borderError;
    }
    .log-stacktrace {
      font-size: 12px;
      opacity: 0.65;
      margin-top: 0.4rem;
      padding-left: 0.6rem;
      border-left: 2px solid ${darkMode ? '#3f3f46' : '#e5e7eb'};
      overflow-x: auto;
    }
    .stack-frame { margin: 0.1rem 0; }

    /* === Structured Data === */
    pre {
      margin: 0;
      padding: 0;
      background: transparent;
      line-height: 1.15;
      overflow-x: auto;
      white-space: pre-wrap;
    }

    /* === JSON semantic tags === */
    .log-key   { color: ${darkMode ? '#93c5fd' : '#2563eb'}; }
    .log-val   { color: ${darkMode ? '#86efac' : '#16a34a'}; }
    .log-punct { opacity: 0.45; }
    .log-border    { opacity: 0.6; }
    .log-hierarchy { opacity: 0.5; user-select: none; }
    .log-prefix, .log-suffix { opacity: 0.55; font-size: 0.9em; }

    /* === BoxNode === */
    fieldset.log-box {
      border: 1px solid ${darkMode ? '#3f3f46' : '#d1d5db'};
      padding: 0.4rem 0.65rem;
      margin: 0.2rem 0;
      background: ${darkMode ? 'rgba(255,255,255,0.012)' : 'rgba(0,0,0,0.01)'};
    }
    fieldset.log-box-rounded { border-radius: 6px; }
    fieldset.log-box-sharp   { border-radius: 0; }
    fieldset.log-box-double  { border-style: double; border-width: 3px; }
    fieldset.log-box-none    { border: none; background: transparent; padding: 0; }
    fieldset.log-box legend {
      font-size: 11px;
      font-weight: 600;
      padding: 0 0.4rem;
      color: ${darkMode ? '#9ca3af' : '#6b7280'};
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    /* === IndentationNode (div) === */
    div.log-indent {
      margin: 0;
      padding-left: max(0.65rem, 1.5vw);
      border-left: 1px solid ${darkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'};
    }

    /* === DecoratedNode === */
    .log-decorated { display: flex; gap: 0.3rem; align-items: baseline; }
    .log-leading   {
      flex-shrink: 0;
      opacity: 0.7; /* Increased for visibility of prefixes */
      user-select: none;
      white-space: pre;
    }
    .log-trailing  {
      flex-shrink: 0;
      margin-left: auto;
      opacity: 0.45;
      user-select: none;
      white-space: pre;
      padding-left: 0.5rem;
    }
    .log-decorated-content { flex: 1; min-width: 0; }

    /* === RowNode === */
    .log-row { display: flex; flex-wrap: wrap; gap: 0.2rem; align-items: baseline; line-height: 1.2; }
    .log-row-cell { max-width: 100%; overflow-wrap: anywhere; }

    /* === FillerNode === */
    hr.log-filler {
      border: none;
      border-top: 1px dashed ${darkMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.15)'};
      margin: 0.3rem 0;
    }

    /* === Lines === */
    p.log-line, div.log-line {
      margin: 0;
      white-space: pre-wrap;
      word-break: break-word;
      line-height: 1.4;
    }
    div.log-indent p,
    div.log-decorated-content p,
    div.log-indent div,
    div.log-decorated-content div {
      margin-top: 0;
      margin-bottom: 0;
    }

    /* === Responsive === */
    @media (max-width: 600px) {
      body { padding: 0.4rem; font-size: 12px; }
      .log-entry { padding: 0.4rem 0.2rem; }
      .log-leading, .log-trailing { max-width: 24px; overflow: hidden; opacity: 0.5; }
      div.log-indent { padding-left: 0.4rem; }
      fieldset.log-box { padding: 0.3rem; }
    }
    """;
  }

  String _escapeHtml(final String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
