part of '../handler.dart';

/// A content-bearing node, carrying text segments.
@immutable
sealed class ContentNode extends LogNode {
  /// Creates a [ContentNode].
  const ContentNode({
    required this.segments,
    super.tags,
  });

  /// The list of styled text segments that make up this content.
  final List<StyledText> segments;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ContentNode &&
          runtimeType == other.runtimeType &&
          listEquals(segments, other.segments) &&
          setEquals(tags, other.tags);

  @override
  int get hashCode =>
      Object.hash(runtimeType, Object.hashAll(segments), Object.hashAll(tags));

  @override
  String toString() => segments.map((final s) => s.toString()).join();
}

/// Primary metadata section (timestamp, level, logger).
final class HeaderNode extends ContentNode {
  const HeaderNode({
    required super.segments,
    super.tags = const {LogTag.header},
  });
}

/// The main log message.
final class MessageNode extends ContentNode {
  const MessageNode({
    required super.segments,
    super.tags = const {LogTag.message},
  });
}

/// Error information.
final class ErrorNode extends ContentNode {
  const ErrorNode({
    required super.segments,
    super.tags = const {LogTag.error},
  });
}

/// Supplementary info (origin, stack trace).
final class FooterNode extends ContentNode {
  const FooterNode({required super.segments, super.tags});
}

/// Diagnostic metadata sections.
final class MetadataNode extends ContentNode {
  const MetadataNode({required super.segments, super.tags});
}
