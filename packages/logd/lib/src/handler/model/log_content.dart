part of '../handler.dart';

/// A leaf node containing actual text content.
///
/// [ContentNode]s hold a list of [StyledText] segments. They represent the
/// payload of the log, such as the timestamp, severity level, or the message
/// itself.
@immutable
sealed class ContentNode extends LogNode {
  /// Creates a [ContentNode].
  const ContentNode({
    required this.segments,
    super.tags,
  });

  /// The list of styled text segments that make up this content.
  final List<StyledText> segments;

  /// Creates a copy of this node with optional new segments or tags.
  ContentNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  });

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ContentNode &&
          runtimeType == other.runtimeType &&
          listEquals(segments, other.segments) &&
          tags == other.tags;

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(segments), tags);

  @override
  String toString() => segments.map((final s) => s.text).join();
}

/// Primary metadata section (timestamp, level, logger).
final class HeaderNode extends ContentNode {
  /// Creates a [HeaderNode].
  const HeaderNode({
    required super.segments,
    super.tags = LogTag.header,
  });

  @override
  HeaderNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      HeaderNode(
        segments: segments ?? this.segments,
        tags: tags ?? this.tags,
      );
}

/// The main log message.
final class MessageNode extends ContentNode {
  /// Creates a [MessageNode].
  const MessageNode({
    required super.segments,
    super.tags = LogTag.message,
  });

  @override
  MessageNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      MessageNode(
        segments: segments ?? this.segments,
        tags: tags ?? this.tags,
      );
}

/// Error information.
final class ErrorNode extends ContentNode {
  /// Creates an [ErrorNode].
  const ErrorNode({
    required super.segments,
    super.tags = LogTag.error,
  });

  @override
  ErrorNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      ErrorNode(
        segments: segments ?? this.segments,
        tags: tags ?? this.tags,
      );
}

/// Supplementary info (origin, stack trace).
final class FooterNode extends ContentNode {
  /// Creates a [FooterNode].
  const FooterNode({required super.segments, super.tags});

  @override
  FooterNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      FooterNode(
        segments: segments ?? this.segments,
        tags: tags ?? this.tags,
      );
}

/// Diagnostic metadata sections.
final class MetadataNode extends ContentNode {
  /// Creates a [MetadataNode].
  const MetadataNode({required super.segments, super.tags});

  @override
  MetadataNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      MetadataNode(
        segments: segments ?? this.segments,
        tags: tags ?? this.tags,
      );
}

/// A node that fills remaining line width with a character.
@immutable
final class FillerNode extends LogNode {
  /// Creates a [FillerNode].
  const FillerNode(this.char, {super.tags, this.style});

  /// The character used to fill the space.
  final String char;

  /// Optional visual style for the filler characters.
  final LogStyle? style;

  /// Creates a copy of this node with optional new values.
  FillerNode copyWith({
    final String? char,
    final int? tags,
    final LogStyle? style,
  }) =>
      FillerNode(
        char ?? this.char,
        tags: tags ?? this.tags,
        style: style ?? this.style,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is FillerNode &&
          runtimeType == other.runtimeType &&
          char == other.char &&
          tags == other.tags &&
          style == other.style;

  @override
  int get hashCode => Object.hash(runtimeType, char, tags, style);

  @override
  String toString() => char;
}

/// A node that carries raw structured data as a mapping.
///
/// This is used by formatters that want to pass semantic data to specialized
/// encoders (like `JsonEncoder`) while allowing fallback rendering by generic
/// encoders.
@immutable
final class MapNode extends LogNode {
  /// Creates a [MapNode].
  const MapNode(this.map, {super.tags});

  /// The raw mapping data.
  final Map<String, Object?> map;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is MapNode &&
          runtimeType == other.runtimeType &&
          mapEquals(map, other.map) &&
          tags == other.tags;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        Object.hashAll(
          (map.entries.toList()
                ..sort((final a, final b) => a.key.compareTo(b.key)))
              .map((final e) => Object.hash(e.key, e.value)),
        ),
        tags,
      );

  @override
  String toString() => convert.jsonEncode(map);
}

/// A node that carries raw structured data as a list.
@immutable
final class ListNode extends LogNode {
  /// Creates a [ListNode].
  const ListNode(this.list, {super.tags});

  /// The raw list data.
  final List<Object?> list;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ListNode &&
          runtimeType == other.runtimeType &&
          listEquals(list, other.list) &&
          tags == other.tags;

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(list), tags);

  @override
  String toString() => convert.jsonEncode(list);
}
