import 'package:logd/src/stack_trace/stack_trace.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

void main() {
  group('Web Source Mapping Tests', () {
    late String sourceMapJson;

    setUpAll(() {
      final builder = SourceMapBuilder();
      final sourceUrl = Uri.parse('package:my_app/main.dart');

      final sourceLoc = SourceLocation(
        0,
        line: 9, // line 10
        column: 4, // column 5
        sourceUrl: sourceUrl,
      );

      final targetLoc = SourceLocation(
        0,
        line: 99, // line 100
        column: 19, // column 20
      );

      builder.addLocation(sourceLoc, targetLoc, 'myOriginalMethod');
      sourceMapJson = builder.toJson('main.dart.js');
    });

    tearDown(() {
      StackTraceParser.clearSourceMaps();
    });

    test('resolves Chrome format 1 stack frame', () {
      StackTraceParser.registerSourceMap('main.dart.js', sourceMapJson);

      const parser = StackTraceParser();
      // Emulate Chrome stack trace
      final trace = StackTrace.fromString(
        'Error\n'
        '    at mangledMethod (http://localhost:8080/main.dart.js:100:20)\n'
        '    at caller (http://localhost:8080/main.dart.js:200:30)',
      );

      final result = parser.parse(stackTrace: trace, maxFrames: 1);
      final caller = result.caller;

      expect(caller, isNotNull);
      expect(caller!.filePath, equals('package:my_app/main.dart'));
      expect(caller.lineNumber, equals(10));
      expect(caller.columnNumber, equals(5));
      expect(caller.methodName, equals('myOriginalMethod'));
    });

    test('resolves Firefox/Safari format 1 stack frame', () {
      StackTraceParser.registerSourceMap('main.dart.js', sourceMapJson);

      const parser = StackTraceParser();
      // Emulate Firefox stack trace
      final trace = StackTrace.fromString(
        'mangledMethod@http://localhost:8080/main.dart.js:100:20\n'
        'caller@http://localhost:8080/main.dart.js:200:30',
      );

      final result = parser.parse(stackTrace: trace, maxFrames: 1);
      final caller = result.caller;

      expect(caller, isNotNull);
      expect(caller!.filePath, equals('package:my_app/main.dart'));
      expect(caller.lineNumber, equals(10));
      expect(caller.columnNumber, equals(5));
      expect(caller.methodName, equals('myOriginalMethod'));
    });

    test('returns original frame on unregistered file or parser mismatch', () {
      StackTraceParser.registerSourceMap('main.dart.js', sourceMapJson);

      const parser = StackTraceParser();
      // Emulate Chrome stack trace on unregistered file
      final trace = StackTrace.fromString(
        'Error\n'
        '    at mangledMethod (http://localhost:8080/other.dart.js:100:20)',
      );

      final result = parser.parse(stackTrace: trace, maxFrames: 1);
      final caller = result.caller;

      expect(caller, isNotNull);
      expect(caller!.filePath, equals('http://localhost:8080/other.dart.js'));
      expect(caller.lineNumber, equals(100));
      expect(caller.columnNumber, equals(20));
      expect(caller.methodName, equals('mangledMethod'));
    });

    test('clears registered source maps', () {
      StackTraceParser.registerSourceMap('main.dart.js', sourceMapJson);
      StackTraceParser.clearSourceMaps();

      const parser = StackTraceParser();
      final trace = StackTrace.fromString(
        'Error\n'
        '    at mangledMethod (http://localhost:8080/main.dart.js:100:20)',
      );

      final result = parser.parse(stackTrace: trace, maxFrames: 1);
      final caller = result.caller;

      expect(caller, isNotNull);
      expect(caller!.filePath, equals('http://localhost:8080/main.dart.js'));
      expect(caller.lineNumber, equals(100));
      expect(caller.columnNumber, equals(20));
      expect(caller.methodName, equals('mangledMethod'));
    });
  });
}
