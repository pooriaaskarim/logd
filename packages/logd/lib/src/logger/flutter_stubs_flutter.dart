import 'package:flutter/foundation.dart';

import '../../logd.dart';

void attachToFlutterErrors() {
  FlutterError.onError = (final details) {
    Logger.get().error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
}
