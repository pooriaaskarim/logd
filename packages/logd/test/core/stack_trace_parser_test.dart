import 'package:logd/src/stack_trace/stack_trace.dart';
import 'package:test/test.dart';

void main() {
  group('StackTraceParser Tests', () {
    test('should parse VM stack frames correctly', () {
      const parser = StackTraceParser();
      final trace = StackTrace.fromString('''
#0      MyClass.myMethod (package:my_app/src/file.dart:12:34)
#1      otherFunction (package:my_app/src/file.dart:56)
''');

      final result = parser.parse(stackTrace: trace, maxFrames: 2);
      expect(result.caller, isNotNull);
      expect(result.caller!.className, equals('MyClass'));
      expect(result.caller!.methodName, equals('myMethod'));
      expect(result.caller!.filePath, equals('package:my_app/src/file.dart'));
      expect(result.caller!.lineNumber, equals(12));
      expect(result.caller!.columnNumber, equals(34));

      expect(result.frames, hasLength(2));
      expect(result.frames[1].className, isEmpty);
      expect(result.frames[1].methodName, equals('otherFunction'));
      expect(result.frames[1].lineNumber, equals(56));
      expect(result.frames[1].columnNumber, isNull);
    });

    test('should parse Chrome/V8 stack frames correctly', () {
      const parser = StackTraceParser();
      final trace = StackTrace.fromString('''
Error
    at MyClass.myMethod (http://localhost:8080/main.dart.js:123:45)
    at http://localhost:8080/main.dart.js:678:90
''');

      final result = parser.parse(stackTrace: trace, maxFrames: 2);
      expect(result.caller, isNotNull);
      expect(result.caller!.className, equals('MyClass'));
      expect(result.caller!.methodName, equals('myMethod'));
      expect(
        result.caller!.filePath,
        equals('http://localhost:8080/main.dart.js'),
      );
      expect(result.caller!.lineNumber, equals(123));
      expect(result.caller!.columnNumber, equals(45));

      expect(result.frames, hasLength(2));
      expect(result.frames[1].methodName, equals('<anonymous>'));
      expect(result.frames[1].lineNumber, equals(678));
      expect(result.frames[1].columnNumber, equals(90));
    });

    test('should parse Firefox/Safari stack frames correctly', () {
      const parser = StackTraceParser();
      final trace = StackTrace.fromString('''
myMethod@http://localhost:8080/main.dart.js:123:45
http://localhost:8080/main.dart.js:678:90
''');

      final result = parser.parse(stackTrace: trace, maxFrames: 2);
      expect(result.caller, isNotNull);
      expect(result.caller!.className, isEmpty);
      expect(result.caller!.methodName, equals('myMethod'));
      expect(
        result.caller!.filePath,
        equals('http://localhost:8080/main.dart.js'),
      );
      expect(result.caller!.lineNumber, equals(123));
      expect(result.caller!.columnNumber, equals(45));

      expect(result.frames, hasLength(2));
      expect(result.frames[1].methodName, equals('<anonymous>'));
      expect(result.frames[1].lineNumber, equals(678));
      expect(result.frames[1].columnNumber, equals(90));
    });

    test('should parse DDC stack frames correctly', () {
      const parser = StackTraceParser();
      final trace = StackTrace.fromString('''
packages/logd/src/logger/logger.dart 1741:35                                   _log
packages/flutter_notification_queue/src/core/facade.dart 93:13                 configure
packages/logd/src/logger/logger.dart 1664:12
''');

      final result = parser.parse(stackTrace: trace, maxFrames: 3);
      expect(result.caller, isNotNull);
      expect(result.caller!.className, isEmpty);
      expect(result.caller!.methodName, equals('_log'));
      expect(
        result.caller!.filePath,
        equals('packages/logd/src/logger/logger.dart'),
      );
      expect(result.caller!.lineNumber, equals(1741));
      expect(result.caller!.columnNumber, equals(35));

      expect(result.frames, hasLength(3));
      expect(result.frames[1].methodName, equals('configure'));
      expect(result.frames[1].lineNumber, equals(93));
      expect(result.frames[2].methodName, equals('<anonymous>'));
      expect(result.frames[2].lineNumber, equals(1664));
    });

    test(
      'should skip/include asynchronous suspensions based on includeAsyncOrigin',
      () {
        // 1. includeAsyncOrigin = false (default)
        const parserDefault = StackTraceParser();
        final trace = StackTrace.fromString('''
#0      MyClass.myMethod (package:my_app/src/file.dart:12:34)
<asynchronous suspension>
#1      otherFunction (package:my_app/src/file.dart:56:78)
''');

        final resultDefault =
            parserDefault.parse(stackTrace: trace, maxFrames: 3);
        expect(resultDefault.frames, hasLength(2));
        expect(
          resultDefault.frames.any(
            (final f) => f.methodName == '<asynchronous suspension>',
          ),
          isFalse,
        );

        // 2. includeAsyncOrigin = true
        const parserWithAsync = StackTraceParser(includeAsyncOrigin: true);
        final resultWithAsync =
            parserWithAsync.parse(stackTrace: trace, maxFrames: 3);
        expect(resultWithAsync.frames, hasLength(3));
        expect(
          resultWithAsync.frames[1].methodName,
          equals('<asynchronous suspension>'),
        );
        expect(
          resultWithAsync.frames[1].fullMethod,
          equals('<asynchronous suspension>'),
        );
        expect(resultWithAsync.frames[1].lineNumber, equals(0));
      },
    );

    test(
      'should filter out packages using ignorePackages (VM and Web formats)',
      () {
        const parser = StackTraceParser(ignorePackages: ['logd']);
        final trace = StackTrace.fromString('''
#0      LogdClass.logMethod (package:logd/src/file.dart:10:20)
#1      MyClass.myMethod (package:my_app/src/file.dart:12:34)
#2      IgnoredWeb (http://localhost:8080/packages/logd/src/web_file.js:15:30)
#3      AllowedWeb (http://localhost:8080/packages/my_app/src/web_file.js:40:50)
''');

        final result = parser.parse(stackTrace: trace, maxFrames: 4);
        expect(result.caller, isNotNull);
        expect(result.caller!.className, equals('MyClass'));
        expect(result.caller!.methodName, equals('myMethod'));

        expect(result.frames, hasLength(2));
        expect(result.frames[0].className, equals('MyClass'));
        expect(result.frames[1].className, isEmpty);
        expect(result.frames[1].methodName, equals('AllowedWeb'));
      },
    );

    test('should parse actual native stack trace correctly on current platform',
        () {
      const parser = StackTraceParser();
      final trace = StackTrace.current;
      final result = parser.parse(stackTrace: trace, maxFrames: 1);

      expect(result.caller, isNotNull);
      expect(result.caller!.methodName, isNotEmpty);
      expect(result.caller!.filePath, isNotEmpty);
      expect(result.caller!.lineNumber, greaterThan(0));
    });
  });
}
