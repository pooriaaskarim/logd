part 'callback_info.dart';

typedef FrameFilter = bool Function(String frame);

class StackTraceParser {
  const StackTraceParser({
    this.ignorePackages = const [],
    this.customFilter,
  });

  final List<String> ignorePackages;
  final FrameFilter? customFilter;

  /// Extracts the first relevant caller frame.
  CallbackInfo? extractCaller({
    required final StackTrace stackTrace,
    final int skipFrames = 0,
  }) {
    final lines = stackTrace.toString().split('\n');
    int index = skipFrames;

    while (index < lines.length) {
      final frame = lines[index].trim();
      if (frame.isEmpty) {
        index++;
        continue;
      }

      if (_shouldIgnoreFrame(frame)) {
        index++;
        continue;
      }

      final info = parseFrame(frame);
      if (info != null) {
        return info;
      }

      index++;
    }
    return null;
  }

  bool _shouldIgnoreFrame(final String frame) {
    if (customFilter != null && !customFilter!(frame)) {
      return true;
    }
    return ignorePackages.any((final pkg) => frame.contains('package:$pkg/'));
  }

  CallbackInfo? parseFrame(final String frame) {
    // #0 Class.method (package:path/file.dart:25:7)
    final reg = RegExp(r'#\d+\s+([^\s]+)\s+\((.+):(\d+):\d+\)');
    final match = reg.firstMatch(frame);
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
      className: className.replaceFirst(RegExp(r'^_'), ''),
      methodName: methodName,
      filePath: filePath,
      lineNumber: lineNumber,
      fullMethod: fullMethod,
    );
  }
}
