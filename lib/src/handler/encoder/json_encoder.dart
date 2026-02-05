part of '../handler.dart';

/// Encodes logs into a JSON string wrapper.
///
/// This encoder is useful for transporting text logs to JSON-accepting
/// endpoints
/// while maintaining the original text format in the "message" field.
///
/// It attempts to extract semantic metadata (timestamp, logger name, error)
/// from [StyledText] tags if they are present.
class JsonEncoder implements LogEncoder<String> {
  /// Creates a [JsonEncoder].
  const JsonEncoder();

  @override
  String encode(final LogDocument document, final LogLevel level) {
    if (document.nodes.isEmpty) {
      return '{}';
    }

    final data = <String, dynamic>{
      'level': level.name,
      'timestamp': DateTime.now().toIso8601String(), // Fallback
      ...document.metadata,
    };

    final messageBuffer = StringBuffer();
    String? extractedTimestamp;
    String? extractedLogger;
    String? extractedError;

    void processNode(final LogNode node) {
      switch (node) {
        case final ContentNode s:
          if (messageBuffer.isNotEmpty) {
            messageBuffer.write('\n');
          }
          for (final segment in s.segments) {
            messageBuffer.write(segment.text);

            if (segment.tags.contains(LogTag.timestamp)) {
              extractedTimestamp = segment.text.trim();
            }
            if (segment.tags.contains(LogTag.loggerName)) {
              extractedLogger = segment.text.trim();
            }
            if (segment.tags.contains(LogTag.error)) {
              extractedError = segment.text.trim();
            }
          }
        case final LayoutNode c:
          for (final child in c.children) {
            processNode(child);
          }
      }
    }

    for (final node in document.nodes) {
      processNode(node);
    }

    if (extractedTimestamp != null) {
      data['timestamp'] = extractedTimestamp;
    }
    if (extractedLogger != null) {
      data['logger'] = extractedLogger;
    }
    if (extractedError != null) {
      data['error'] = extractedError;
    }

    data['message'] = messageBuffer.toString();

    return jsonEncode(data);
  }
}
