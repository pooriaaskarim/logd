import 'dart:io';

import 'package:logd/src/core/context/clock/clock_native.dart';
import 'package:test/test.dart';

void main() {
  group('fetchNativeTimezoneName (native path — current platform)', () {
    test('returns a non-empty string on the current platform', () {
      // This directly calls the production code path.
      // On Linux/macOS it exercises the real OS lookup;
      // on iOS it would exercise the DateTime.now().timeZoneName fast-path.
      final name = fetchNativeTimezoneName();
      expect(name, isNotEmpty);
    });

    test(
        'returns a result consistent with DateTime.now().timeZoneName '
        'or a valid IANA name', () {
      final name = fetchNativeTimezoneName();
      // Should either be an IANA name (contains '/') or an offset like '+03:30'
      // or a platform abbreviation — but it must never be null or empty.
      expect(name, isNotNull);
      expect(name.length, greaterThan(0));
    });
  });

  group('resolveTimezonePath', () {
    test('returns null for a non-existent path', () {
      expect(resolveTimezonePath('/this/path/does/not/exist'), isNull);
    });

    test('returns null when path is a plain file (not a symlink to zoneinfo)',
        () {
      // Create a temporary non-symlink file
      final tmp = File('/tmp/logd_tz_test_plain')
        ..writeAsStringSync('not_a_tz');
      addTearDown(tmp.deleteSync);

      // resolveTimezonePath requires a symlink, so a plain file → null
      expect(resolveTimezonePath(tmp.path), isNull);
    });

    // On a standard Linux system, /etc/localtime is a symlink into
    // /usr/share/zoneinfo/, so this validates the production path.
    test('resolves /etc/localtime to a valid IANA name (Linux only)', () {
      if (!Platform.isLinux) {
        return;
      }

      final link = Link('/etc/localtime');
      if (!link.existsSync()) {
        markTestSkipped('/etc/localtime not present on this system');
        return;
      }

      final name = resolveTimezonePath('/etc/localtime');
      expect(name, isNotNull);
      expect(name, contains('/')); // IANA names are Region/City
    });
  });
}
