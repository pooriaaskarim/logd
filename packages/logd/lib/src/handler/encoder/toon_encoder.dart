part of '../handler.dart';

/// An encoder that serializes [LogDocument]s into Token-Oriented Object
/// Notation (TOON).
///
/// It uses the configuration (delimiter, columns, sortKeys, etc.) stored in the
/// document's metadata to produce headers and delimited rows. It handles
/// recursive formatting for nested Maps and Lists within the TOON rows.
class ToonEncoder implements LogEncoder<String> {
  /// Creates a [ToonEncoder].
  const ToonEncoder();

  @override
  String? preamble(final LogLevel level, {final LogDocument? document}) {
    if (document == null) {
      return null;
    }
    final arrayName = document.metadata['toon_array'] as String? ?? 'logs';
    final columns = document.metadata['toon_columns'] as List<String>?;
    if (columns == null) {
      return null;
    }

    final columnStr = columns.join(',');
    return '$arrayName[]{$columnStr}:';
  }

  @override
  String? postamble(final LogLevel level) => null;

  @override
  String encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level, {
    final int? width,
  }) {
    final delimiter = document.metadata['toon_delimiter'] as String? ?? '\t';
    final columns = document.metadata['toon_columns'] as List<String>?;
    final sortKeys = document.metadata['toon_sort_keys'] as bool? ?? false;
    final maxDepth = document.metadata['toon_max_depth'] as int? ?? 5;

    final output = StringBuffer();

    final nodes = document.nodes;
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is MapNode) {
        if (columns != null) {
          final row = columns.map((final col) {
            final val = node.map[col];
            return _formatValue(
              val,
              0,
              delimiter: delimiter,
              sortKeys: sortKeys,
              maxDepth: maxDepth,
            );
          }).join(delimiter);
          output.write(row);
        } else {
          output.write(node.map.toString());
        }
      } else {
        output.write(node.toString());
      }
      if (i < nodes.length - 1) {
        output.write('\n');
      }
    }

    return output.toString();
  }

  String _formatValue(
    final Object? value,
    final int depth, {
    required final String delimiter,
    required final bool sortKeys,
    required final int maxDepth,
  }) {
    if (value == null) {
      return '';
    }
    if (depth >= maxDepth && (value is Map || value is List)) {
      return '...';
    }

    if (value is Map) {
      final entries = value.entries.toList();
      if (sortKeys) {
        entries.sort(
          (final a, final b) => a.key.toString().compareTo(b.key.toString()),
        );
      }
      final items = entries
          .map(
            (final e) => '${_formatValue(
              e.key,
              depth + 1,
              delimiter: delimiter,
              sortKeys: sortKeys,
              maxDepth: maxDepth,
            )}:'
                '${_formatValue(
              e.value,
              depth + 1,
              delimiter: delimiter,
              sortKeys: sortKeys,
              maxDepth: maxDepth,
            )}',
          )
          .join(',');
      return '{$items}';
    } else if (value is List) {
      final items = value
          .map(
            (final e) => _formatValue(
              e,
              depth + 1,
              delimiter: delimiter,
              sortKeys: sortKeys,
              maxDepth: maxDepth,
            ),
          )
          .join(',');
      return '[$items]';
    }

    return _escape(
      value.toString(),
      delimiter,
    );
  }

  String _escape(final String value, final String delimiter) {
    if (value.isEmpty) {
      return '';
    }
    final hasDelimiter = value.contains(delimiter);
    final hasNewline = value.contains('\n') || value.contains('\r');
    final hasSpecial = value.contains('{') ||
        value.contains('}') ||
        value.contains('[') ||
        value.contains(']') ||
        value.contains(':') ||
        value.contains(',');

    if (!hasDelimiter && !hasNewline && !hasSpecial && !value.contains('"')) {
      return value;
    }

    return '"${value.replaceAll('"', r'\"').replaceAll(
          '\n',
          r'\n',
        ).replaceAll(
          '\r',
          r'\r',
        )}"';
  }
}
