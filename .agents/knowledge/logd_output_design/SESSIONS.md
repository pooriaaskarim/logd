# logd Output Pipeline — Session Log
> Append-only. Each entry records what was attempted, what broke, and what was learned.
> Never edit past entries. Add new entries at the top.

---

## 2026-08-05 | v0.9.3 | Target Handlers & ADR-006 Resolution

### What We Did
- Standardized 8 pre-wired `{Target}Handler` convenience subclasses (`ConsoleHandler`, `HtmlFileHandler`, `JsonFileHandler`, `PlainFileHandler`, `ToonFileHandler`, `MarkdownFileHandler`, `HttpDashboardHandler`, `MemoryHandler`).
- Added `.async()` background isolate constructors across all output-bound handlers (~15 µs return).
- Standardized the `{Target}Handler` convention across core and satellite ecosystem (`logd_sqlite`, `logd_sentry`).

---

## 2026-07-28 | v0.9.1 | TOON Format, AutoEncoder Protocol & Self-Declaring Wrapping

### What We Did
- Introduced native `ToonFormatter` and `ToonEncoder` for token-efficient LLM logging and telemetry streams.
- Added `AutoEncoder` protocol contract (`'logd.encoder'`), allowing sinks to automatically detect the matching physical encoder from `document.metadata`.
- Added `requiredStrategy` to `LogEncoder`, allowing `EncodingSink` to self-default to `WrappingStrategy.document` for `HtmlEncoder` without manual user configuration.
- Added bounded `MemorySink<T>` ring buffer.

---

## 2026-07-22 | v0.9.0 | Theming Unification & HtmlStylesheet Extraction

### What We Did
- Resolved theme ownership: `StyleDecorator` is now the single source of truth for semantic tag-to-style resolution and attaches `document.metadata['logd.theme']`.
- Decoupled CSS/JS generation from `HtmlEncoder` into `HtmlStylesheet` and `DefaultHtmlStylesheet`.
- Added `LogBrightness` (`dark`, `light`), `lightScheme`, and theme presets (`DarkTheme`, `LightTheme`, `PastelTheme`, `HighContrastTheme`).

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
