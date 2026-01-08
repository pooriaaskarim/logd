import 'dart:io' as io;
import 'package:meta/meta.dart';

import 'clock/clock.dart';
import 'io/file_system.dart';

/// Internal Service Locator for System Dependencies.
///
/// Allows injecting [Clock] and [FileSystem] implementations
/// to facilitate testing without global state.
/// This class is internal to the package and not exported.
@internal
abstract class Context {
  const Context._();

  static Clock _clock = const SystemClock();
  static FileSystem _fileSystem = const LocalFileSystem();

  /// The current [Clock] instance.
  /// Consumers should use [Context.clock] instead of [DateTime.now].
  static Clock get clock => _clock;

  /// The current [FileSystem] instance.
  /// Consumers should use [Context.fileSystem] instead of
  /// [io.File] or [io.Directory].
  static FileSystem get fileSystem => _fileSystem;

  /// Injects a custom [Clock] for testing.
  @visibleForTesting
  static void setClock(final Clock clock) {
    _clock = clock;
  }

  /// Injects a custom [FileSystem] for testing.
  @visibleForTesting
  static void setFileSystem(final FileSystem fileSystem) {
    _fileSystem = fileSystem;
  }

  /// Resets providers to their default implementations.
  @visibleForTesting
  static void reset() {
    _clock = const SystemClock();
    _fileSystem = const LocalFileSystem();
  }
}
