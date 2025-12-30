import 'package:flutter_test/flutter_test.dart';
import 'package:logd/src/core/clock/clock.dart';
import 'package:logd/src/core/context.dart';
import 'package:logd/src/core/io/file_system.dart';

class MockClock implements Clock {
  @override
  DateTime get now => DateTime(2020);

  @override
  String? get timezoneName => 'Mock/Zone';
}

class MockFileSystem implements FileSystem {
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  group('Context', () {
    tearDown(() {
      Context.reset(); // Restore defaults after each test
    });

    test('default clock is SystemClock', () {
      expect(Context.clock, isA<SystemClock>());
    });

    test('default fileSystem is LocalFileSystem', () {
      expect(Context.fileSystem, isA<LocalFileSystem>());
    });

    test('setClock updates the clock provider', () {
      final mockClock = MockClock();
      Context.setClock(mockClock);
      expect(Context.clock, equals(mockClock));
      expect(Context.clock.now.year, equals(2020));
    });

    test('setFileSystem updates the file system provider', () {
      final mockFS = MockFileSystem();
      Context.setFileSystem(mockFS);
      expect(Context.fileSystem, equals(mockFS));
    });

    test('reset restores defaults', () {
      Context.setClock(MockClock());
      Context.setFileSystem(MockFileSystem());

      Context.reset();

      expect(Context.clock, isA<SystemClock>());
      expect(Context.fileSystem, isA<LocalFileSystem>());
    });
  });
}
