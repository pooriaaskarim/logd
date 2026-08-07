// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('LogBrightness & Theme Presets', () {
    test('should report correct LogBrightness for DarkTheme and LightTheme',
        () {
      const darkTheme = DarkTheme();
      const lightTheme = LightTheme();

      expect(darkTheme.brightness, equals(LogBrightness.dark));
      expect(lightTheme.brightness, equals(LogBrightness.light));
    });

    test('should resolve high contrast light colors in DefaultHtmlStylesheet',
        () {
      const stylesheet = DefaultHtmlStylesheet();
      const lightTheme = LightTheme();

      final css = stylesheet.buildCss(lightTheme);

      expect(css, contains('--bg: #ffffff;'));
      expect(css, contains('--fg: #000000;'));
      expect(css, contains('--warning: #92400e;')); // High contrast amber
    });
  });
}
