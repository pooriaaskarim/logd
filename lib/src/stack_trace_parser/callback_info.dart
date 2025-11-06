part of 'stack_trace_parser.dart';

class CallbackInfo {
  const CallbackInfo({
    required this.className,
    required this.methodName,
    required this.filePath,
    required this.lineNumber,
    required this.fullMethod,
  });

  final String className;
  final String methodName;
  final String filePath;
  final int lineNumber;
  final String fullMethod;

  @override
  String toString() => '$className.$methodName ($filePath:$lineNumber)';
}
