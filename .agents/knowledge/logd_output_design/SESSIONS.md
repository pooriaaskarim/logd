# logd Output Pipeline — Session Log
> Append-only. Each entry records what was attempted, what broke, and what was learned.
> Never edit past entries. Add new entries at the top.

---

## 2026-07-08 | v0.8.7 | Session d882b493

### What We Did
- Added interactive control panel (search, level filters, live counters) to `HtmlEncoder` preamble
- Added copy-to-clipboard button per log entry with micro-animations
- Added `_lightColorMap` — high-contrast hex values for WCAG AA on white background
- Added `darkMode: bool?` field to `HtmlEncoder` to allow explicit surface override
- Fixed `_css()` to use `_isDark` as single source of truth (previously had two independent heuristics)
- Fixed XSS escaping for map keys
- Fixed `TableNode` column fallback when `columnWidths` is empty or undefined
- Overhauled all HTML showcase examples to delete stale output files at startup
- Regenerated all HTML regression goldens

### Bugs Hit
1. `html_box_showcase.dart` was missing `WrappingStrategy.document` → silent unstyled output
2. `html_enhanced_showcase.dart` light theme appeared dark: `pastelScheme` uses `LogColor.cyan` for debug, which `_isDark` heuristic read as dark
3. `_css()` computed `bg`/`fg` independently from `_isDark` — two parallel heuristics that could disagree

### Root Causes Identified
- `HtmlEncoder` had no clean surface context concept. `darkMode` is a workaround for the missing `LogSurface`.
- `WrappingStrategy` is not communicated at the encoder level — user must know to set it for `HtmlEncoder`, or get silent failure.
- Theme ownership split (StyleDecorator / AnsiEncoder / HtmlEncoder) has no clear resolution order.

### Decisions Explicitly Deferred
- `LogSurface` not added to `LogTheme` yet — workaround (`_darkMode`) is good enough pending design maturity
- `LogOutput` facade not implemented — premature without user validation of API shape
- `lightScheme` not added to `LogColorScheme` — `_lightColorMap` in `HtmlEncoder` is a stopgap; correct home still unclear
