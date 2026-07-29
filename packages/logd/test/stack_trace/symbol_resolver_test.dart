import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('SymbolResolver Tests', () {
    test('StackTraceParser applies symbolResolver to obfuscated frames', () {
      final obfuscatedTrace = StackTrace.fromString('''
#0 _k3\$2 (package:myapp/main.dart:42:10)
#1 _a9\$1 (package:myapp/auth.dart:15:5)
''');

      final symbolMap = <String, String>{
        '_k3\$2': 'UserService.fetchProfile',
        '_a9\$1': 'AuthManager.login',
      };

      final parser = StackTraceParser(
        symbolResolver: (final symbol) => symbolMap[symbol],
      );

      final result = parser.parse(stackTrace: obfuscatedTrace, maxFrames: 2);

      expect(result.caller, isNotNull);
      expect(result.caller!.className, equals('UserService'));
      expect(result.caller!.methodName, equals('fetchProfile'));
      expect(
        result.caller!.fullMethod,
        equals('UserService.fetchProfile'),
      );

      expect(result.frames, hasLength(2));
      expect(result.frames[1].className, equals('AuthManager'));
      expect(result.frames[1].methodName, equals('login'));
    });

    test('falls back to original frame info if symbolResolver returns null',
        () {
      final obfuscatedTrace = StackTrace.fromString('''
#0 _unknownSymbol (package:myapp/main.dart:10:5)
''');

      final parser = StackTraceParser(
        symbolResolver: (final symbol) => null,
      );

      final result = parser.parse(stackTrace: obfuscatedTrace);

      expect(result.caller, isNotNull);
      expect(result.caller!.methodName, equals('_unknownSymbol'));
    });
  });
}
