import 'package:logd/logd.dart';
import 'package:logd/src/stack_trace/stack_trace.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart';

void main() {
  print('=== logd Web Source Mapping Showcase ===\n');

  // 1. Emulate a mangled browser JS stack trace frame
  // e.g. mangledMethod at line 100, column 20 in http://localhost:8080/main.dart.js
  const mangledFrame =
      '    at mangledMethod (http://localhost:8080/main.dart.js:100:20)';
  final jsTrace = StackTrace.fromString('Error\n$mangledFrame');

  print('1. Mangled JS Frame input:');
  print(mangledFrame.trim());
  print('');

  // 2. Programmatically construct a mock source map mapping that location
  // JS compiled location: line 100, column 20 (0-indexed line: 99, column: 19)
  // Dart original location: package:my_app/services/auth.dart, line 42, column 12 (0-indexed line: 41, column: 11)
  final builder = SourceMapBuilder();
  final sourceUrl = Uri.parse('package:my_app/services/auth.dart');

  final sourceLoc = SourceLocation(
    0,
    line: 41,
    column: 11,
    sourceUrl: sourceUrl,
  );

  final targetLoc = SourceLocation(
    0,
    line: 99,
    column: 19,
  );

  builder.addLocation(sourceLoc, targetLoc, 'loginUser');
  final sourceMapJson = builder.toJson('main.dart.js');

  // 3. Register the source map on the StackTraceParser
  StackTraceParser.registerSourceMap('main.dart.js', sourceMapJson);
  print('2. Registered source map for "main.dart.js".');
  print('');

  // 4. Parse the trace using StackTraceParser
  const parser = StackTraceParser();
  final result = parser.parse(stackTrace: jsTrace, maxFrames: 1);
  final caller = result.caller;

  print('3. Resolved Original Dart Call Frame:');
  if (caller != null) {
    print('  - Original File  : ${caller.filePath}');
    print('  - Original Method: ${caller.methodName}');
    print('  - Line / Column  : ${caller.lineNumber}:${caller.columnNumber}');
    print('  - Full Method    : ${caller.fullMethod}');
  } else {
    print('  - Failed to parse frame.');
  }
}
