# logd Output Pipeline — Status
> Current as of: v0.9.4 | Updated: 2026-08-19

---

## Current Version Snapshot

| Component | State |
|---|---|
| `AnsiEncoder` | ✅ Stable. Pure rendering, delegates all color/styling to `LogTheme`. |
| `HtmlEncoder` | ✅ Stable. Extracted `HtmlStylesheet`, interactive control panel, copy button. |
| `MarkdownEncoder` | ✅ Stable. GitHub-flavored markdown rendering for CI/CD artifacts. |
| `ToonEncoder` | ✅ Stable since v0.9.1. Token-optimized output for LLMs and WebSocket streams. |
| `LogTheme` / `LogColorScheme` | ✅ Stable since v0.9.0/v0.9.2. `LogBrightness.dark`/`light`, `lightScheme`, preset themes. |
| `WrappingStrategy` | ✅ Stable since v0.9.1. Encoders self-declare `requiredStrategy`. Sinks auto-default. |
| `StyleDecorator` | ✅ Stable since v0.9.0. Sole source of truth attaching `document.metadata['logd.theme']`. |
| `TargetHandler` Subclasses | ✅ Stable since v0.9.3 (ADR-006). Pre-wired subclasses eliminate pipeline friction. |
| `FileSink` | ✅ Stable. Auto-flush, time/size rotation, dispose lifecycle. |
| `LogOutput` facade | 🔲 Superseded by `{Target}Handler` convenience subclasses (`ConsoleHandler`, `HtmlFileHandler`, etc.). |

---

## What Was Done (v0.8.8 – v0.9.4)

- **v0.9.3**: Implemented ADR-006 Pre-Wired `{Target}Handler` convenience subclasses (`ConsoleHandler`, `HtmlFileHandler`, `JsonFileHandler`, `PlainFileHandler`, `ToonFileHandler`, `MarkdownFileHandler`, `HttpDashboardHandler`, `MemoryHandler`) and `.async()` isolate factories.
- **v0.9.2**: Fixed `LogBrightness` theme serialization across isolate boundaries; added high-contrast light mode palettes (`--warning: #92400e;`).
- **v0.9.1**: Added native `ToonFormatter` / `ToonEncoder`; added `AutoEncoder` protocol auto-detection contract (`'logd.encoder'`); enabled encoders to self-declare `requiredStrategy`.
- **v0.9.0**: Unified theming with `StyleDecorator` as sole authority; decoupled CSS/JS into `HtmlStylesheet`; added standard theme presets (`DarkTheme`, `LightTheme`, `PastelTheme`, `HighContrastTheme`).
- **v0.8.8**: Added `HttpServerSink` live dashboard viewer with live WebSocket streaming and raw HTML segment rendering.

---

## Open Questions

| Question | Blocker | Status |
|---|---|---|
| Should `HtmlEncoder` read surface from `LogTheme` or remain self-contained? | Needs `LogSurface` first | Deferred |
| Should `WrappingStrategy` be removed from public API? | Needs encoder `requiredStrategy` first | Deferred |
| Should `LogOutput` be a separate package? | Depends on dependency tree growth | Unknown |
| Should `Logger.dispose()` exist for lifecycle? | Need real-world non-trivial app patterns | Unknown |
| Should `LogSurface` support more than dark/light? | Accessibility modes unknown | Deferred |

---

## Known Traps (Do Not Repeat)

- `HtmlEncoder` requires `WrappingStrategy.document`. Omitting it silently produces unstyled HTML with no error.
- `FileSink.dispose()` MUST be called when using `HtmlEncoder`. Missing it silently omits the JS postamble.
- `darkMode: bool` on `HtmlEncoder` is a stopgap. Do NOT expand its usage — it exists pending `LogSurface`.
- Theme ownership is split (StyleDecorator / AnsiEncoder / HtmlEncoder). Do NOT attempt to unify without a deprecation plan + major version boundary.
- Append mode + HTML/Markdown = corrupted output if stale files exist. Always delete before regenerating.
- `pastelScheme` uses `LogColor.cyan` for debug — the `_isDark` heuristic read this as dark mode (bug). Explicit `darkMode` field was the fix.
