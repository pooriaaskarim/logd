// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Describes the overall surface brightness of a log theme.
///
/// Used by renderers (such as HTML stylesheets) to select an appropriate color
/// palette for the output surface.
enum LogBrightness {
  /// Optimized for dark backgrounds.
  dark,

  /// Optimized for light backgrounds.
  light,
}
