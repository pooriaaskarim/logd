import 'dart:io' as io;
import 'package:meta/meta.dart';

part 'timestamp.dart';
part 'timezone.dart';

@visibleForTesting

/// A placeholder class for time-related functionality.
class Time {
  const Time._();
  static DateTime Function() _timeProvider = DateTime.now;

  @visibleForTesting
  static void setTimeProvider(final DateTime Function() provider) {
    _timeProvider = provider;
  }
}
