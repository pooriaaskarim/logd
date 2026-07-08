# Output Design Session Log
> Append-only. Each entry records what was learned and what changed in that session.
> This is the living memory of design decisions for the output pipeline.

---

## 2026-07-08 — v0.8.7 Era — Session d882b493

### Context
Working on HtmlEncoder improvements: control panel, copy-to-clipboard, dark/light
mode themes, and refactoring examples to be stable and re-runnable.

### What We Built
- Added interactive control panel (search, level filters, expand/collapse) to HtmlEncoder
- Added copy-to-clipboard button per log entry (JS postamble)
- Added XSS escaping for map keys
- Fixed table column fallback when `columnWidths` is empty
- Added `_lightColorMap` for high-contrast light-mode colors in HtmlEncoder
- Added `_darkMode` field to `HtmlEncoder` to allow explicit surface override
- Fixed `_css()` to use `_isDark` as single source of truth for bg/fg
- All HTML showcase examples now delete stale output files at startup
- All HTML regression goldens regenerated

### Bugs Discovered
1. `html_box_showcase.dart` was missing `WrappingStrategy.document` → unstyled output, no CSS
2. `html_enhanced_showcase.dart` light theme appeared dark because `pastelScheme`
   uses `LogColor.cyan` for debug, which the `_isDark` heuristic read as dark mode
3. `_css()` computed `bg`/`fg` independently from `_isDark`, creating two parallel
   heuristics that could disagree → fixed by making `_isDark` the single source of truth

### Root Causes Identified
- `HtmlEncoder` had no clean concept of surface context. `darkMode` was a workaround
  for the absence of `LogSurface` in `LogTheme`.
- `WrappingStrategy` is not communicated to the user at the point of use.
  The `FileSink` default of `WrappingStrategy.none` silently breaks `HtmlEncoder`.
- Theme ownership is split across three API locations with no clear priority.

### Design Tensions Documented
- See `critique/current_state.md` (7 tensions, each with known/unknown split)
- See `vision/future_api_direction.md` (3-layer API model, migration philosophy)

### Decisions NOT Made (intentionally deferred)
- No `LogSurface` added to `LogTheme` yet — the workaround (`_darkMode` field) is
  good enough for now and avoids a breaking change while the design matures.
- No `LogOutput` facade — premature without user validation.
- No `lightScheme` in `LogColorScheme` — the `_lightColorMap` in `HtmlEncoder`
  is a stopgap. The right home for this mapping is still unclear.

### Open Questions to Revisit
- Should `HtmlEncoder` read surface from `LogTheme` or remain self-contained?
- Should `WrappingStrategy` be removed from the public API surface entirely?
- When is the right moment to introduce `LogOutput` as a beginner path?
