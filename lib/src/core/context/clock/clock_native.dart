import 'dart:io' as io;

import 'package:meta/meta.dart';

/// Fetches timezone name for native platforms (non-web).
///
/// Uses platform-specific methods (e.g., getprop for Android).
/// Throws Exception on fail; caller handles default/logging.
String fetchNativeTimezoneName() {
  final platform = io.Platform.operatingSystem.toLowerCase();
  switch (platform) {
    case 'android':
      try {
        final processResult =
            io.Process.runSync('getprop', ['persist.sys.timezone']);
        final timezoneString = processResult.stdout.toString().trim();
        if (timezoneString.isNotEmpty) {
          return timezoneString;
        }
      } on io.ProcessException catch (e) {
        throw Exception('Android timezone fetch failed: ${e.message}');
      } catch (e) {
        throw Exception('Android timezone fetch failed: $e');
      }
      throw Exception('Android timezone fetch failed: empty response');
    case 'ios':
    case 'macos':
      for (final path in [
        '/etc/localtime',
        '/var/db/timezone/localtime',
      ]) {
        try {
          final name = resolveTimezonePath(path);
          if (name != null) {
            return name;
          }
        } on io.FileSystemException catch (_) {
          // Path not found or permission denied, continue to next path
        } catch (_) {
          // Any other error, continue to next path or systemsetup
        }
      }

      // Fallback to systemsetup only on macOS
      if (platform == 'macos') {
        try {
          final processResult =
              io.Process.runSync('systemsetup', ['-gettimezone']);
          final regexMatch = RegExp('Time Zone: (.+)')
              .firstMatch(processResult.stdout.toString());
          if (regexMatch != null) {
            return regexMatch.group(1)!;
          }
        } on io.ProcessException catch (_) {
          // systemsetup command failed or not found
        } catch (_) {
          // Any other error during process execution
        }
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
      try {
        final processResult = io.Process.runSync(
          'timedatectl',
          ['show', '--value', '--property=Timezone'],
        );
        final timezoneString = processResult.stdout.toString().trim();
        if (timezoneString.isNotEmpty) {
          return timezoneString;
        }
      } on io.ProcessException catch (_) {
        // Continue to other linux methods
      }
      throw Exception('Linux timezone fetch failed');
    case 'windows':
      try {
        final processResult = io.Process.runSync(
          'powershell',
          ['-Command', '[System.TimeZoneInfo]::Local.Id'],
        );
        final timezoneString = processResult.stdout.toString().trim();
        if (timezoneString.isNotEmpty) {
          return timezoneString;
        }
      } on io.ProcessException catch (e) {
        throw Exception('Windows timezone fetch failed: ${e.message}');
      } catch (e) {
        throw Exception('Windows timezone fetch failed: $e');
      }
      throw Exception('Windows timezone fetch failed: empty response');
    default:
      throw UnsupportedError(
        'Platform $platform not supported for timezone fetch',
      );
  }
}

/// Resolves a timezone name from a symlink path.
///
/// Returns null if the path is not a symlink to a valid zoneinfo file.
@visibleForTesting
String? resolveTimezonePath(final String path) {
  final link = io.Link(path);
  if (!link.existsSync()) {
    return null;
  }
  final realPath = link.resolveSymbolicLinksSync();
  const zoneInfoPrefix = '/usr/share/zoneinfo/';
  if (realPath.contains(zoneInfoPrefix)) {
    return realPath
        .substring(realPath.indexOf(zoneInfoPrefix) + zoneInfoPrefix.length);
  }
  return null;
}
