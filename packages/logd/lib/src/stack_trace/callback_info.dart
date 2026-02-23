part of 'stack_trace.dart';

/// Data class holding parsed information from a stack frame.
@immutable
class CallbackInfo {
  const CallbackInfo({
    required this.className,
    required this.methodName,
    required this.filePath,
    required this.lineNumber,
    required this.fullMethod,
  });

  /// The class name from the stack frame (empty if none).
  final String className;

  /// The method name from the stack frame.
  final String methodName;

  /// The file path where the call occurred.
  final String filePath;

  /// The line number in the file.
  final int lineNumber;

  /// The full method string from the stack (e.g., 'Class.method').
  final String fullMethod;

  @override
  String toString() => '$className.$methodName ($filePath:$lineNumber)';

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is CallbackInfo &&
          runtimeType == other.runtimeType &&
          className == other.className &&
          methodName == other.methodName &&
          filePath == other.filePath &&
          lineNumber == other.lineNumber &&
          fullMethod == other.fullMethod;

  @override
  int get hashCode => Object.hash(
        className,
        methodName,
        filePath,
        lineNumber,
        fullMethod,
      );
}
