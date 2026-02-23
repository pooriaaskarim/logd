part of '../handler.dart';

/// Semantic hint strings for [DecoratedNode.leadingHint] and
/// [DecoratedNode.trailingHint].
///
/// These constants are the shared vocabulary between [LogFormatter]s (which
/// set the hints) and [TerminalLayout] (which interprets them). Using named
/// constants instead of raw strings prevents typos, enables IDE navigation,
/// and makes the coupling explicit.
abstract final class DecorationHint {
  /// Prefix for a structured-format **header** line (fills with `_`).
  static const String structuredHeader = 'structured_header';

  /// Prefix for a structured-format **separator** line (fills with `_`).
  static const String structuredSeparator = 'structured_separator';

  /// Prefix for a structured-format **message/body** line.
  ///
  /// On continuation lines, the prefix column is replaced with spaces to
  /// preserve visual alignment.
  static const String structuredMessage = 'structured_message';

  /// Prefix for hierarchy / stack-trace indentation.
  static const String hierarchyTrace = 'hierarchy_trace';
}
