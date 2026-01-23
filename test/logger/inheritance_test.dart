import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    Logger.clearRegistry();
  });

  test('freezeInheritance with partial child overrides', () {
    // Parent config
    Logger.configure('global', logLevel: LogLevel.trace, enabled: false);

    // Child config: override enabled only
    Logger.configure('app.ui', enabled: true);

    var child = Logger.get('app.ui');
    expect(child.enabled, isTrue); // Own config
    expect(child.logLevel, LogLevel.trace); // Inherited

    // Freeze intermediate
    // Note: 'app' is the parent of 'app.ui'
    Logger.get('app').freezeInheritance();

    child = Logger.get('app.ui'); // Re-fetch logic resolves again
    expect(child.enabled, isTrue); // Should still own enabled
    expect(
      child.logLevel,
      LogLevel.trace,
    ); // Should be frozen from parent values at time of freeze

    // Change global parent
    Logger.configure('global', logLevel: LogLevel.error);

    child = Logger.get('app.ui');
    // It should remain trace because 'app' (intermediate) froze its state down
    // to 'app.ui'.
    // Logic check: 'app' inherits 'trace' from global.
    // 'app'.freezeInheritance() takes 'app's effective config (trace)
    // and pushes it to children
    // if they don't have it set. 'app.ui' doesn't have logLevel set,
    // so it gets 'trace' set explicitly.
    expect(child.logLevel, LogLevel.trace);
  });
}
