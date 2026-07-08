# logd Output Pipeline — Architecture
> Stable reference. Invariants that must not be violated.
> Update this only when a design decision is permanently resolved.

---

## The Pipeline (What Every Stage Does)

```
LogEntry
  → LogFormatter       (Semantic IR builder — produces LogDocument)
  → LogDecorator(s)    (Semantic IR mutators — BoxDecorator, TimestampDecorator, etc.)
  → TerminalLayout     (Physical layout — wrapping, tab-stops, ANSI segment slicing)
  → LogEncoder         (Renderer — ANSI, HTML, Markdown, JSON, Binary)
  → LogSink            (Output — Console, File, Socket, Isolate)
```

**The single most important invariant:** Formatters and Decorators operate on the Semantic IR only (`LogDocument`, `LogNode`). They never touch terminal width, pixel counts, or string rendering. `TerminalLayout` is the sole authority on physical layout.

---

## What Is Correct and Must Be Preserved

### Semantic IR Contract
`LogDocument` + `LogNode` as the pivot between production and rendering is the right architectural bet. Formatters build meaning; encoders render it. This decoupling must never be collapsed.

### `LogTheme.getStyle(level, tags)`
Semantic color resolution — base level color, tag overrides, style merges — is well-designed and handles the common case. The `AnsiEncoder` correctly delegates all color decisions here. Every other encoder should follow this model.

### Logger Hierarchy & Inheritance
Hierarchical logger naming with inherited config is a proven pattern. `Logger.configure`, `Logger.get`, and `configureMultiple` are the right API shape. Do not flatten this.

### `TerminalLayout` Boundary
Physical layout is correctly separated from semantic construction. This boundary must remain intact.

### `AnsiEncoder` as the Model Encoder
`AnsiEncoder` does not invent its own dark/light concept because the terminal owns that context. This is the correct approach that every other encoder should aspire to.

---

## Known Design Debts (Active)

### 1. Theme Has No Single Owner
Theme configuration exists in three places simultaneously:
- `StyleDecorator(theme:)` — pre-bakes styles into the document
- `AnsiEncoder(theme:)` — resolves colors during ANSI encoding
- `HtmlEncoder(theme:)` — resolves colors during HTML encoding

These are inconsistent. A user cannot set a theme in one place and trust propagation.
**Target state:** `Handler.theme` propagates through the pipeline automatically.
**Blocker:** Clean migration requires deprecation + major version boundary.

### 2. `LogSurface` Is Missing from `LogTheme`
`HtmlEncoder` infers dark/light via a heuristic (`debug != LogColor.white → dark`). This breaks for custom schemes. The `darkMode: bool?` parameter is a workaround.
**Target state:** `enum LogSurface { dark, light }` as a field in `LogTheme`.
**Additive — no breaking change.**

### 3. `WrappingStrategy` Is a Manual User Tax
`HtmlEncoder` requires `WrappingStrategy.document`. The user must set this manually. Omitting it silently produces broken HTML — no error.
**Target state:** Encoders declare `requiredStrategy`, sinks read it automatically.

### 4. No Beginner Path
Every setup requires 4–5 nested concepts assembled correctly. No "zero-decisions" entry point exists.
**Target state:** `LogOutput` facade — a factory that produces a correctly configured `Handler`. Not a new abstraction, just a named constructor.

### 5. Sink Lifecycle Is Manual
`dispose()` is manually called by the user. For `HtmlEncoder` it is mandatory (writes the JS postamble). Missing it silently produces broken HTML.
**Target state:** `Logger.dispose()` or a `LogSession` handle pattern closes the loop.

---

## WCAG Color Map (Light Mode, Resolved Values)

These values satisfy WCAG AA (≥4.5:1) on a `#ffffff` background. They live in `HtmlEncoder._lightColorMap` as a stopgap pending `LogColorScheme.lightScheme`.

| LogColor | Hex | Contrast |
|---|---|---|
| `green` | `#15803d` | 6.4:1 |
| `brightGreen` | `#166534` | 10.1:1 |
| `yellow` | `#b45309` | 4.8:1 |
| `brightYellow` | `#92400e` | 7.4:1 |
| `blue` | `#1d4ed8` | 6.6:1 |
| `brightBlue` | `#1e40af` | 9.5:1 |
| `white` | `#334155` | 4.6:1 |
| `brightWhite` | `#0f172a` | 15.5:1 |

Badge text rule: `color: isDark ? '#000000' : '#ffffff'` to preserve legibility on both surfaces.

---

## File Integrity Rules

- `FileSink` defaults to `LogFileMode.append`. HTML and Markdown require single-document integrity (one preamble, one postamble). **Always delete existing output files before regenerating.**
- `TableNode` without `columnWidths` falls back to `grid-template-columns: repeat(maxCols, 1fr)`. Safe — but explicit widths are preferred.

---

## Future API Shape (Three-Layer Model)

```
Level 1 (Beginner) → LogOutput facade       — zero decisions
Level 2 (Standard) → Handler + Sink + ...   — current API, cleaned up
Level 3 (Expert)   → Full pipeline access   — unchanged internals
```

### Design Principles
1. **Surface-Medium Orthogonality:** Terminal ANSI is surface-agnostic (the terminal owns its palette). Files (HTML, Markdown) are controlled surfaces. `LogSurface` decouples these.
2. **Self-Declaring Modularity:** Encoders declare structural constraints (`requiredStrategy`). Sinks read it. The user should not coordinate these manually.
3. **Lifecycle Safety:** Sinks that write complex file types require deterministic finalization. Long-term target: Session/Handle pattern with atomic teardown.
4. **Migration Discipline:** Deprecate, don't remove. Additive first. Facades only after real-world validation.
