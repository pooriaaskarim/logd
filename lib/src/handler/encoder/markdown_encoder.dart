part of '../handler.dart';

/// An encoder that produces GitHub-Flavored Markdown.
///
/// [MarkdownEncoder] translates semantic [LogDocument] nodes into Markdown
/// syntax.
/// It uses headings for [HeaderNode], blockquotes for [BoxNode] and
/// [IndentationNode], and standard Markdown emphasis for [LogStyle]s.
class MarkdownEncoder implements LogEncoder<String> {
  /// Creates a [MarkdownEncoder].
  ///
  /// - [headingLevel]: The base heading level for [HeaderNode] (default: 3).
  const MarkdownEncoder({
    this.headingLevel = 3,
  });

  /// The base heading level for log headers.
  final int headingLevel;

  @override
  String encode(final LogDocument document, final LogLevel level) {
    if (document.nodes.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    for (final node in document.nodes) {
      buffer.writeln(_renderNode(node, level, 0));
    }

    return buffer.toString().trimRight();
  }

  String _renderNode(
    final LogNode node,
    final LogLevel level,
    final int depth,
  ) {
    switch (node) {
      case final HeaderNode n:
        final h = '#' * headingLevel.clamp(1, 6);
        final levelIcon = _getLevelIcon(level);
        return '$h $levelIcon ${_renderContent(n)}\n';

      case final ContentNode n:
        return _renderContent(n);

      case final BoxNode n:
        final buffer = StringBuffer();
        if (n.title != null) {
          buffer
            ..writeln('**${n.title}**')
            ..writeln('---');
        }
        for (final child in n.children) {
          final content = _renderNode(child, level, depth + 1);
          buffer.writeln(_indent(content, depth + 1));
        }
        return buffer.toString();

      case final IndentationNode n:
        final buffer = StringBuffer();
        for (final child in n.children) {
          final content = _renderNode(child, level, depth + 1);
          buffer.writeln(_indent(content, depth + 1));
        }
        return buffer.toString();

      case final DecoratedNode n:
        final buffer = StringBuffer();
        for (final child in n.children) {
          buffer.writeln(_renderNode(child, level, depth));
        }
        return buffer.toString();

      case final GroupNode n:
        return n.children
            .map((final c) => _renderNode(c, level, depth))
            .join('\n');
    }
  }

  String _renderContent(final ContentNode node) {
    final buffer = StringBuffer();
    final isHeader = node is HeaderNode;

    for (final segment in node.segments) {
      var text = segment.text;
      final tags = segment.tags;

      // Apply Markdown styling based on tags or explicit style
      if (isHeader ||
          tags.contains(LogTag.header) ||
          tags.contains(LogTag.level)) {
        text = '**$text**';
      } else if (tags.contains(LogTag.error)) {
        text = '***$text***'; // Bold-italic for errors
      } else if (tags.contains(LogTag.timestamp) ||
          tags.contains(LogTag.origin)) {
        text = '_${text.trim()}_';
      }

      buffer.write(text);
    }
    return buffer.toString();
  }

  String _indent(final String text, final int depth) {
    final prefix = '> ' * depth;
    return text
        .split('\n')
        .map((final line) => line.isEmpty ? prefix.trimRight() : '$prefix$line')
        .join('\n');
  }

  /// Gets an emoji icon for the log level.
  String _getLevelIcon(final LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return '🔍';
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}
