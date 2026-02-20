part of '../handler.dart';

/// An encoder that transforms [LogDocument] into HTML markup.
///
/// It traverses the semantic tree and renders nodes as HTML elements, applying
/// CSS classes based on [LogTag]s.
@immutable
class HtmlEncoder implements LogEncoder<String> {
  const HtmlEncoder();

  @override
  String encode(
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

  String _escapeHtml(final String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
