import 'dart:js_interop' as jsi;
import 'dart:js_interop_unsafe';

/// Fetches the browser's timezone name using the JavaScript Intl API.
///
/// Intentions: Retrieves the user's system timezone in IANA format for web
/// environments, where dart:io is unavailable. This ensures consistent
/// timezone detection across platforms without external dependencies.
/// Throws Exception on failure (e.g., API unavailable); caller handles default/logging.
///
/// How to use:
/// - Called internally by Time.timeZoneNameFetcher() on web.
/// - Example: String tz = fetchWebTimeZoneName(); // 'Europe/London'
String fetchWebTimeZoneName() {
  try {
    final intl = jsi.globalContext.getProperty<jsi.JSObject?>('Intl'.toJS);
    if (intl == null) {
      throw Exception('Intl API not available');
    }
    final dtfConstructor =
        intl.getProperty<jsi.JSFunction?>('DateTimeFormat'.toJS);
    if (dtfConstructor == null) {
      throw Exception('DateTimeFormat not available');
    }
    // Call constructor: new Intl.DateTimeFormat()
    final dtf = dtfConstructor.callAsConstructor<jsi.JSObject?>(jsi.JSArray());
    if (dtf == null) {
      throw Exception('Failed to create DateTimeFormat');
    }
    // Call resolvedOptions()
    final options = dtf.callMethod<jsi.JSObject?>('resolvedOptions'.toJS);
    if (options == null) {
      throw Exception('resolvedOptions failed');
    }
    // Access timeZone property
    final timeZone = options.getProperty<jsi.JSString?>('timeZone'.toJS);
    final result = timeZone?.toDart;
    if (result == null || result.isEmpty) {
      throw Exception('timeZone property empty');
    }
    return result;
  } catch (e) {
    throw Exception('Web timezone fetch failed: $e');
  }
}
