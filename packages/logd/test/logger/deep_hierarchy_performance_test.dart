// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Deep Logger Hierarchy Performance Tests', () {
    tearDown(() {
      Logger.reset();
    });

    test('resolves configurations on 12-level hierarchy in under 1ms', () {
      final names = List.generate(12, (final i) => 'level_$i').join('.');

      Logger.configure('global', logLevel: LogLevel.debug);
      Logger.configure(names, logLevel: LogLevel.error);

      // Warm up lazy caches and internal logger warnings
      final warmUp = Logger.get(names);
      expect(warmUp.logLevel, equals(LogLevel.error));

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        final logger = Logger.get(names);
        final level = logger.logLevel;
        expect(level, equals(LogLevel.error));
      }
      stopwatch.stop();

      final avgUs = stopwatch.elapsedMicroseconds / 1000;
      expect(
        avgUs,
        lessThan(50),
        reason: 'Cached deep hierarchy resolution must take '
            'under 50 microseconds per lookup',
      );
    });
  });
}
