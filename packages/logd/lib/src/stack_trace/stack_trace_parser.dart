part of 'stack_trace.dart';

typedef FrameFilter = bool Function(String frame);

/// Parser for extracting useful information from stack traces.
@immutable
class StackTraceParser {
  const StackTraceParser({
    this.ignorePackages = const [],
    this.customFilter,
  });

  /// List of package prefixes to ignore during parsing
  /// (e.g., 'logd' to skip internals).
  final List<String> ignorePackages;

  /// Optional custom filter function to decide if a frame should be ignored.
  final FrameFilter? customFilter;

  bool _shouldIgnoreFrame(final String frame) {
    if (customFilter != null && !customFilter!(frame)) {
      return true;
    }
    return ignorePackages.any((final pkg) => frame.contains('package:$pkg/'));
  }

  // Compiled once per class load for performance.
  static final _frameRegex = RegExp(r'#\d+\s+(.+)\s+\((.+):(\d+)(?::\d+)?\)');

  /// Parses a stack trace in a single pass, extracting both the caller
  /// (first non-ignored frame) and up to [maxFrames] stack frames.
  ///
  /// Parameters:
  /// - [stackTrace]: The full stack trace to parse.
  /// - [skipFrames]: Number of initial frames to skip (default 0).
  /// - [maxFrames]: Maximum number of stack frames to collect (default 0).
  ///
  /// Returns: A [StackFrameSet] with the caller and collected frames.
  StackFrameSet parse({
    required final StackTrace stackTrace,
    final int skipFrames = 0,
    final int maxFrames = 0,
  }) {
    final lines = stackTrace.toString().split('\n');
    CallbackInfo? caller;
    final frames = <CallbackInfo>[];
    int index = skipFrames;

    while (index < lines.length) {
      final frame = lines[index].trim();
      index++;
      if (frame.isEmpty) {
        continue;
      }
      if (_shouldIgnoreFrame(frame)) {
        continue;
      }

      final info = _parseFrame(frame);
      if (info == null) {
        continue;
      }

      caller ??= info;
      if (maxFrames > 0 && frames.length < maxFrames) {
        frames.add(info);
      }
      if (maxFrames == 0 || frames.length >= maxFrames) {
        break;
      }
    }

    return StackFrameSet(caller: caller, frames: frames);
  }

  CallbackInfo? _parseFrame(final String frame) {
    // #0 Class.method (package:path/file.dart:25:7)
    final match = _frameRegex.firstMatch(frame);
    if (match == null) {
      return null;
    }

    final fullMethod = match.group(1)!;
    final filePath = match.group(2)!;
    final lineNumber = int.parse(match.group(3)!);

    final dotIndex = fullMethod.lastIndexOf('.');
    final className = dotIndex != -1 ? fullMethod.substring(0, dotIndex) : '';
    final methodName =
        dotIndex != -1 ? fullMethod.substring(dotIndex + 1) : fullMethod;

    return CallbackInfo(
      className: className.replaceFirst(RegExp('^_'), ''),
      methodName: methodName,
      filePath: filePath,
      lineNumber: lineNumber,
      fullMethod: fullMethod,
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is StackTraceParser &&
          runtimeType == other.runtimeType &&
          listEquals(ignorePackages, other.ignorePackages) &&
          customFilter == other.customFilter;

  @override
  int get hashCode => Object.hash(Object.hashAll(ignorePackages), customFilter);
}
