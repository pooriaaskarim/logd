part of '../handler.dart';

/// An encoder that transforms [LogDocument] into Markdown (GFM) markup.
///
/// It translates the semantic structure of the log into Markdown elements:
/// - [HeaderNode]: Headers (###)
/// - [MessageNode]: Bold text (**message**)
/// - [LogTag.collapsible]: `<details>` blocks for collapsible content.
/// - [LogTag.stackFrame]: Code blocks (```).
@immutable
class MarkdownEncoder implements LogEncoder<String> {
  /// Creates a [MarkdownEncoder].
  const MarkdownEncoder();

  @override
  String? preamble(final LogLevel level, {final LogDocument? document}) => null;

  @override
  String? postamble(final LogLevel level) => null;

  @override
  String encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level, {
    final int? width,
  }) {
    final buffer = StringBuffer();

    for (final node in document.nodes) {
      _renderNode(buffer, node);
    }

    return buffer.toString().trimRight();
  }

  void _renderNode(final StringBuffer buffer, final LogNode node) {
    if ((node.tags & LogTag.collapsible) != 0) {
      _renderCollapsible(buffer, node);
      return;
    }

    if (node is HeaderNode) {
      buffer.writeln('### ${_renderContent(node)}');
    } else if (node is MessageNode) {
      buffer.writeln('\n**${_renderContent(node)}**');
    } else if (node is ErrorNode) {
      buffer
        ..writeln('\n> [!ERROR]')
        ..writeln('> ${_renderContent(node)}');
    } else if (node is FooterNode) {
      _renderFooter(buffer, node);
    } else if (node is IndentationNode) {
      for (final child in node.children) {
        _renderNode(buffer, child);
      }
    } else if (node is DecoratedNode) {
      for (final child in node.children) {
        _renderNode(buffer, child);
      }
    } else if (node is GroupNode) {
      for (final child in node.children) {
        _renderNode(buffer, child);
      }
    } else if (node is ParagraphNode) {
      for (final child in node.children) {
        _renderNode(buffer, child);
      }
    }
  }

  void _renderCollapsible(final StringBuffer buffer, final LogNode node) {
    final summary =
        (node.tags & LogTag.stackFrame) != 0 ? 'Stack Trace' : 'Details';
    buffer
      ..writeln('\n<details>')
      ..writeln('<summary>$summary</summary>\n');

    if (node is ContentNode) {
      if ((node.tags & LogTag.stackFrame) != 0) {
        buffer
          ..writeln('```')
          ..writeln(_renderContent(node))
          ..writeln('```');
      } else {
        buffer.writeln(_renderContent(node));
      }
    } else if (node is LayoutNode) {
      for (final child in node.children) {
        _renderNode(buffer, child);
      }
    }

    buffer.writeln('\n</details>');
  }

  void _renderFooter(final StringBuffer buffer, final FooterNode node) {
    if ((node.tags & LogTag.stackFrame) != 0) {
      buffer
        ..writeln('\n```')
        ..write(_renderContent(node))
        ..writeln('```');
    } else {
      buffer.writeln(_renderContent(node));
    }
  }

  String _renderContent(final ContentNode node) =>
      node.segments.map((final s) => s.text).join();
}
