/// Describes the overall brightness of a log theme.
///
/// Used by renderers (such as HTML stylesheets) to select an appropriate color
/// palette for the output surface (e.g. dark page vs. light page).
enum LogBrightness {
  /// Optimized for dark backgrounds.
  dark,

  /// Optimized for light backgrounds.
  light,
}
