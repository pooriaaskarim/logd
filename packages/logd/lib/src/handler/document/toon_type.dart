part of '../handler.dart';

/// Semantic data types supported by the TOON protocol.
///
/// These types provide hints to machine parsers (like LLMs) about the
/// content and format of each column in a TOON log stream.
@immutable
class ToonType {
  const ToonType(this.name, [this.parameter]);

  /// A standard ISO 8601 timestamp.
  static const iso8601 = ToonType('iso8601');

  /// An enumerated value (e.g., LogLevel).
  static const enumeration = ToonType('enum');

  /// A standard string.
  static const string = ToonType('string');

  /// A message that may contain Markdown formatting.
  static const markdown = ToonType('markdown');

  /// A multi-line stack trace.
  static const stacktrace = ToonType('stacktrace');

  /// A structured object (Map or List) serialized in TOON notation.
  static const object = ToonType('object');

  /// The base name of the type.
  final String name;

  /// Optional parameter for the type (e.g., enum values).
  final String? parameter;

  @override
  String toString() {
    if (parameter != null) {
      return '$name($parameter)';
    }
    return name;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ToonType &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          parameter == other.parameter;

  @override
  int get hashCode => Object.hash(name, parameter);
}
