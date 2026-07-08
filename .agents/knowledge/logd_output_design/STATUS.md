# logd Output Pipeline — Status
> Current as of: v0.8.7 | Updated: 2026-07-08

---

## Current Version Snapshot

| Component | State |
|---|---|
| `AnsiEncoder` | ✅ Stable. Correct design, delegate all color to `LogTheme`. |
| `HtmlEncoder` | ⚠️ Functional but has design debt. Interactive control panel added in v0.8.7. |
| `MarkdownEncoder` | 🔲 Unknown — not yet deeply reviewed. |
| `LogTheme` / `LogColorScheme` | ⚠️ Missing `LogSurface`. Dark/light heuristic is a workaround. |
| `WrappingStrategy` | ⚠️ Still a manual user tax. Not yet self-declared by encoders. |
| `StyleDecorator` | ⚠️ One of three theme owners. No single source of truth. |
| `FileSink` | ⚠️ Lifecycle (dispose) is manual. Silent failure if omitted for HTML. |
| `LogOutput` facade | ❌ Not yet implemented. Waiting for user validation. |

---

## What Was Just Done (v0.8.7)

- Added interactive control panel (search, level filters, live counters) to `HtmlEncoder`
- Added copy-to-clipboard per log entry (JS postamble)
- Added `_lightColorMap` for WCAG-compliant light-mode colors
- Added `darkMode: bool` field to `HtmlEncoder` as an explicit surface override
- Fixed `_css()` to use `_isDark` as the single truth (was two parallel heuristics)
- All HTML showcase examples now delete stale files at startup (append-mode integrity)
- XSS escaping added for map keys
- Fixed `TableNode` column fallback when `columnWidths` is empty
- All HTML goldens regenerated

---

## Next Steps (Prioritized)

### 1. `LogSurface` in `LogTheme` ← Unblocks everything downstream
Additive change. No breaking API impact.
```dart
enum LogSurface { dark, light }
class LogTheme {
  final LogSurface surface; // new field
  static const dark  = LogTheme(surface: LogSurface.dark,  ...);
  static const light = LogTheme(surface: LogSurface.light, ...);
}
```
Once this exists: `HtmlEncoder.darkMode` is deprecated, `_lightColorMap` moves to `LogColorScheme.lightScheme`.

### 2. `lightScheme` in `LogColorScheme`
The WCAG-AA values are already known (see ARCHITECTURE.md). This is a pure addition.

### 3. Encoder declares `requiredStrategy`
```dart
abstract interface class LogEncoder {
  WrappingStrategy get requiredStrategy => WrappingStrategy.none;
}
class HtmlEncoder implements LogEncoder {
  @override WrappingStrategy get requiredStrategy => WrappingStrategy.document;
}
```
`EncodingSink` reads this automatically. `WrappingStrategy` disappears from public API.

### 4. `LogOutput` facade (deferred — do after steps 1–3)
Only ship after 2–3 real production use cases validate the API shape. Not yet.

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
