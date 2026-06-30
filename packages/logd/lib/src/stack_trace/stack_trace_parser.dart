part of 'stack_trace.dart';

/// Filter function to decide if a frame should be ignored.
typedef FrameFilter = bool Function(String frame);

/// Parser for extracting useful information from stack traces.
@immutable
class StackTraceParser {
  /// Creates a [StackTraceParser] with optional ignored packages and filter.
  const StackTraceParser({
    this.ignorePackages = const [],
    this.customFilter,
    this.includeAsyncOrigin = false,
  });

  /// List of package prefixes to ignore during parsing
  /// (e.g., 'logd' to skip internals).
  final List<String> ignorePackages;

  /// Optional custom filter function to decide if a frame should be ignored.
  final FrameFilter? customFilter;

  /// Whether to include asynchronous suspension lines as frames.
  final bool includeAsyncOrigin;

  bool _shouldIgnoreFrame(final String frame) {
    if (customFilter != null && !customFilter!(frame)) {
      return true;
    }
    return ignorePackages.any(
      (final pkg) =>
          frame.contains('package:$pkg/') || frame.contains('packages/$pkg/'),
    );
  }

  // --- Regexes for various environments ---

  // VM Format: #0 Class.method (package:path/file.dart:25:7)
  static final _vmRegex = RegExp(r'#\d+\s+(.+)\s+\((.+?):(\d+)(?::(\d+))?\)');

  // Chrome Format 1: at Class.method (http://localhost:8080/main.dart.js:123:45)
  static final _chromeRegex1 =
      RegExp(r'^\s*at\s+([^\s(]+)\s+\((.+?):(\d+):(\d+)\)');

  // Chrome Format 2: at http://localhost:8080/main.dart.js:123:45
  static final _chromeRegex2 = RegExp(r'^\s*at\s+(.+?):(\d+):(\d+)');

  // Firefox/Safari Format 1: method@http://localhost:8080/main.dart.js:123:45
  static final _firefoxRegex1 = RegExp(r'^([^@\s]+)@(.+?):(\d+):(\d+)');

  // Firefox/Safari Format 2: http://localhost:8080/main.dart.js:123:45
  static final _firefoxRegex2 = RegExp(r'^(.+?):(\d+):(\d+)');

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

      if (frame == '<asynchronous suspension>') {
        if (includeAsyncOrigin) {
          const info = CallbackInfo(
            className: '',
            methodName: '<asynchronous suspension>',
            filePath: '',
            lineNumber: 0,
            fullMethod: '<asynchronous suspension>',
          );
          caller ??= info;
          if (maxFrames > 0 && frames.length < maxFrames) {
            frames.add(info);
          }
          if (maxFrames == 0 || frames.length >= maxFrames) {
            break;
          }
        }
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
    // 1. VM parser
    var match = _vmRegex.firstMatch(frame);
    if (match != null) {
      final fullMethod = match.group(1)!;
      final filePath = match.group(2)!;
      final lineNumber = int.parse(match.group(3)!);
      final columnGroup = match.group(4);
      final columnNumber = columnGroup != null ? int.parse(columnGroup) : null;

      final dotIndex = fullMethod.lastIndexOf('.');
      final className = dotIndex != -1 ? fullMethod.substring(0, dotIndex) : '';
      final methodName =
          dotIndex != -1 ? fullMethod.substring(dotIndex + 1) : fullMethod;

      return CallbackInfo(
        className: className.replaceFirst(RegExp('^_'), ''),
        methodName: methodName,
        filePath: filePath,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        fullMethod: fullMethod,
      );
    }

    // 2. Chrome format 1
    match = _chromeRegex1.firstMatch(frame);
    if (match != null) {
      final fullMethod = match.group(1)!;
      final filePath = match.group(2)!;
      final lineNumber = int.parse(match.group(3)!);
      final columnNumber = int.parse(match.group(4)!);

      final dotIndex = fullMethod.lastIndexOf('.');
      final className = dotIndex != -1 ? fullMethod.substring(0, dotIndex) : '';
      final methodName =
          dotIndex != -1 ? fullMethod.substring(dotIndex + 1) : fullMethod;

      return CallbackInfo(
        className: className.replaceFirst(RegExp('^_'), ''),
        methodName: methodName,
        filePath: filePath,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        fullMethod: fullMethod,
      );
    }

    // 3. Firefox/Safari format 1
    match = _firefoxRegex1.firstMatch(frame);
    if (match != null) {
      final fullMethod = match.group(1)!;
      final filePath = match.group(2)!;
      final lineNumber = int.parse(match.group(3)!);
      final columnNumber = int.parse(match.group(4)!);

      final dotIndex = fullMethod.lastIndexOf('.');
      final className = dotIndex != -1 ? fullMethod.substring(0, dotIndex) : '';
      final methodName =
          dotIndex != -1 ? fullMethod.substring(dotIndex + 1) : fullMethod;

      return CallbackInfo(
        className: className.replaceFirst(RegExp('^_'), ''),
        methodName: methodName,
        filePath: filePath,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        fullMethod: fullMethod,
      );
    }

    // 4. Chrome format 2 (anonymous)
    match = _chromeRegex2.firstMatch(frame);
    if (match != null) {
      final filePath = match.group(1)!;
      final lineNumber = int.parse(match.group(2)!);
      final columnNumber = int.parse(match.group(3)!);
      return CallbackInfo(
        className: '',
        methodName: '<anonymous>',
        filePath: filePath,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        fullMethod: '<anonymous>',
      );
    }

    // 5. Firefox/Safari format 2 (anonymous)
    match = _firefoxRegex2.firstMatch(frame);
    if (match != null) {
      final filePath = match.group(1)!;
      final lineNumber = int.parse(match.group(2)!);
      final columnNumber = int.parse(match.group(3)!);
      return CallbackInfo(
        className: '',
        methodName: '<anonymous>',
        filePath: filePath,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        fullMethod: '<anonymous>',
      );
    }

    return null;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is StackTraceParser &&
          runtimeType == other.runtimeType &&
          listEquals(ignorePackages, other.ignorePackages) &&
          customFilter == other.customFilter &&
          includeAsyncOrigin == other.includeAsyncOrigin;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(ignorePackages),
        customFilter,
        includeAsyncOrigin,
      );
}
