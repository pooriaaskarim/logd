import 'dart:io' as io;

/// Fetches timezone name for native platforms (non-web).
///
/// Uses platform-specific methods (e.g., getprop for Android).
/// Throws Exception on fail; caller handles default/logging.
String fetchNativeTimezoneName() {
  final platform = io.Platform.operatingSystem.toLowerCase();
  switch (platform) {
    case 'android':
      final processResult =
          io.Process.runSync('getprop', ['persist.sys.timezone']);
      final timezoneString = processResult.stdout.toString().trim();
      if (timezoneString.isNotEmpty) {
        return timezoneString;
      }
      throw Exception('Android timezone fetch failed');
    case 'ios':
    case 'macos':
      final processResult = io.Process.runSync('systemsetup', ['-gettimezone']);
      final regexMatch =
          RegExp('Time Zone: (.+)').firstMatch(processResult.stdout.toString());
      if (regexMatch != null) {
        return regexMatch.group(1)!;
      }
      throw Exception('iOS/macOS timezone fetch failed');
    case 'linux':
      final timezoneFile = io.File('/etc/timezone');
      if (timezoneFile.existsSync()) {
        return timezoneFile.readAsStringSync().trim();
      }
      final localtimeLink = io.Link('/etc/localtime');
      if (localtimeLink.existsSync()) {
        try {
          final realPath = localtimeLink.resolveSymbolicLinksSync();
          const zoneInfoPrefix = '/usr/share/zoneinfo/';
          if (realPath.startsWith(zoneInfoPrefix)) {
            return realPath.substring(zoneInfoPrefix.length);
          }
          final parts = realPath.split('/');
          return parts.sublist(parts.length - 2).join('/');
        } on Exception catch (e) {
          throw Exception('Linux localtime fetch failed: $e');
        }
      }
      final processResult = io.Process.runSync(
        'timedatectl',
        ['show', '--value', '--property=Timezone'],
      );
      final timezoneString = processResult.stdout.toString().trim();
      if (timezoneString.isNotEmpty) {
        return timezoneString;
      }
      throw Exception('Linux timezone fetch failed');
    case 'windows':
      final processResult = io.Process.runSync(
        'powershell',
        ['-Command', '[System.TimeZoneInfo]::Local.Id'],
      );
      final timezoneString = processResult.stdout.toString().trim();
      if (timezoneString.isNotEmpty) {
        return timezoneString;
      }
      throw Exception('Windows timezone fetch failed');
    default:
      throw UnsupportedError(
          'Platform $platform not supported for timezone fetch');
  }
}
