part of 'stack_trace.dart';

/// Result of a single-pass stack trace parse.
///
/// Contains both the caller (first non-ignored frame) and any additional
/// stack frames collected up to the configured limit.
@immutable
class StackFrameSet {
  const StackFrameSet({
    required this.caller,
    required this.frames,
  });

  /// The first relevant caller frame, or null if no valid frame was found.
  final CallbackInfo? caller;

  /// Additional stack frames collected (may be empty).
  final List<CallbackInfo> frames;
}
