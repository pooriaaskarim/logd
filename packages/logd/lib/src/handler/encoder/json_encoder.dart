part of '../handler.dart';

/// An encoder that serializes [LogDocument]s into structured JSON.
///
/// It prioritizes [MapNode] and [ListNode] for direct serialization.
/// If multiple nodes are present, they are joined with newlines.
class JsonEncoder implements LogEncoder<String> {
  /// Creates a [JsonEncoder].
  ///
  /// - [indent]: Indentation for pretty printing. If null, compact JSON is
  /// used.
  const JsonEncoder({this.indent});

  /// Optional indentation for pretty printing.
  final String? indent;

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
    final nodes = document.nodes;
    if (nodes.isEmpty) {
      return '';
    }

    final encoder = indent != null
        ? convert.JsonEncoder.withIndent(indent)
        : const convert.JsonCodec().encoder;

    // Optimization: If there's exactly one MapNode or ListNode, serialize its
    // raw data.
    if (nodes.length == 1) {
      final node = nodes.first;
      if (node is MapNode) {
        return encoder.convert(node.map);
      }
      if (node is ListNode) {
        return encoder.convert(node.list);
      }
    }

    // Fallback: Serialize all nodes via toString() and possibly wrap in a list
    // if there are multiple.
    final list =
        nodes.map((final n) => n is MapNode ? n.map : n.toString()).toList();

    return encoder.convert(
      list.length == 1 ? list.first : list,
    );
  }
}
