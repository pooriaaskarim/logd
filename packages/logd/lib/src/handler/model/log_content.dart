// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

part of '../handler.dart';

/// A leaf node containing actual text content.
///
/// [ContentNode]s hold a list of [StyledText] segments. They represent the
/// payload of the log, such as the timestamp, severity level, or the message
/// itself.
///
/// On the `arena_refinement` branch, [ContentNode] and all subclasses are
/// poolable mutable objects. Use [LogArena] to check out and release them.
sealed class ContentNode extends LogNode {
  /// Creates a [ContentNode].
  ContentNode({
    required this.segments,
    super.tags,
  });

  /// The list of styled text segments that make up this content.
  List<StyledText> segments;

  /// Creates a copy of this node with optional new segments or tags.
  ContentNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  });

  @override
  void reset() {
    segments.clear();
    tags = LogTag.none;
  }

  @override
  void releaseRecursive(final LogArena arena) {
    // ContentNodes are leaf nodes — no children to recurse into.
    arena.release(this);
  }

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
  HeaderNode({
    required super.segments,
    super.tags = LogTag.header,
  });

  /// Named constructor for arena pool allocation.
  HeaderNode._pooled() : super(segments: []);

  @override
  HeaderNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      HeaderNode(
        segments: segments ?? List<StyledText>.from(this.segments),
        tags: tags ?? this.tags,
      );
}

/// The main log message.
final class MessageNode extends ContentNode {
  /// Creates a [MessageNode].
  MessageNode({
    required super.segments,
    super.tags = LogTag.message,
  });

  /// Named constructor for arena pool allocation.
  MessageNode._pooled() : super(segments: []);

  @override
  MessageNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      MessageNode(
        segments: segments ?? List<StyledText>.from(this.segments),
        tags: tags ?? this.tags,
      );
}

/// Error information.
final class ErrorNode extends ContentNode {
  /// Creates an [ErrorNode].
  ErrorNode({
    required super.segments,
    super.tags = LogTag.error,
  });

  /// Named constructor for arena pool allocation.
  ErrorNode._pooled() : super(segments: []);

  @override
  ErrorNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      ErrorNode(
        segments: segments ?? List<StyledText>.from(this.segments),
        tags: tags ?? this.tags,
      );
}

/// Supplementary info (origin, stack trace).
final class FooterNode extends ContentNode {
  /// Creates a [FooterNode].
  FooterNode({
    required super.segments,
    super.tags = LogTag.none,
  });

  /// Named constructor for arena pool allocation.
  FooterNode._pooled() : super(segments: []);

  @override
  FooterNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      FooterNode(
        segments: segments ?? List<StyledText>.from(this.segments),
        tags: tags ?? this.tags,
      );
}

/// Diagnostic metadata sections.
final class MetadataNode extends ContentNode {
  /// Creates a [MetadataNode].
  MetadataNode({
    required super.segments,
    super.tags = LogTag.none,
  });

  /// Named constructor for arena pool allocation.
  MetadataNode._pooled() : super(segments: []);

  @override
  MetadataNode copyWith({
    final List<StyledText>? segments,
    final int? tags,
  }) =>
      MetadataNode(
        segments: segments ?? List<StyledText>.from(this.segments),
        tags: tags ?? this.tags,
      );
}

/// A node that fills remaining line width with a character.
final class FillerNode extends LogNode {
  /// Creates a [FillerNode].
  FillerNode(this.char, {super.tags, this.style});

  /// Named constructor for arena pool allocation.
  FillerNode._pooled()
      : char = '',
        style = null;

  /// The character used to fill the space.
  String char;

  /// Optional visual style for the filler characters.
  LogStyle? style;

  @override
  void reset() {
    char = '';
    style = null;
    tags = LogTag.none;
  }

  @override
  void releaseRecursive(final LogArena arena) => arena.release(this);

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
final class MapNode extends LogNode {
  /// Creates a [MapNode].
  MapNode(this.map, {super.tags});

  /// Named constructor for arena pool allocation.
  MapNode._pooled() : map = {};

  /// The raw mapping data.
  Map<String, Object?> map;

  @override
  void reset() {
    map.clear();
    tags = LogTag.none;
  }

  @override
  void releaseRecursive(final LogArena arena) => arena.release(this);

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
final class ListNode extends LogNode {
  /// Creates a [ListNode].
  ListNode(this.list, {super.tags});

  /// Named constructor for arena pool allocation.
  ListNode._pooled() : list = [];

  /// The raw list data.
  List<Object?> list;

  @override
  void reset() {
    list.clear();
    tags = LogTag.none;
  }

  @override
  void releaseRecursive(final LogArena arena) => arena.release(this);

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
