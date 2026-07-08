# Logd Output Pipeline: Current State Critique
> Status: Captured 2026-07-08, v0.8.7-era.
> This document reflects what we know NOW. It will become outdated as logd grows.

---

## What Is Correct and Should Be Preserved

### The Semantic IR Contract (Strong)
`LogDocument` + `LogNode` as the pivot between production and rendering is the
right architectural bet. Formatters build meaning; encoders render it. This
decoupling is sound and should never be collapsed.

### `LogTheme.getStyle(level, tags)` (Strong)
The semantic color resolution — base level color, tag overrides, style merges —
is a well-designed system. It handles the most common use cases and is
extensible. Keep it intact.

### `Logger` Hierarchy & Inheritance (Strong)
Hierarchical logger naming with inherited configuration is a proven pattern
(Python logging, Java logback). The implementation in logd is correct.
`Logger.configure`, `Logger.get`, and `configureMultiple` are the right API shape.

### `AnsiEncoder` (Strong)
Correctly delegates all color decisions to `LogTheme`. Does not invent its own
dark/light concept because the terminal owns that context. This is the model
every other encoder should aspire to.

### `TerminalLayout` Boundary (Strong)
Physical layout is correctly separated from semantic construction. The
`TerminalLayout` is the sole authority on wrapping, tab-stops, and ANSI
segment slicing. This must remain intact.

---

## What Is Immature and Needs to Grow

### 1. Formatter/Encoder Naming Boundary
**Current:** `LogFormatter` = content builder. `LogEncoder` = visual renderer.
Both affect output appearance but have completely different names and roles.
A new user assumes the Formatter is where appearance is configured.

**What we know:** The naming does not communicate the conceptual split.
**What we don't know yet:** Whether renaming is the right fix, or whether
better documentation at the API boundary is sufficient. Real user feedback
is needed before a breaking rename.

**Tension to watch:** Some teams may already have mental models built
around the current names. A rename before a v1.0 boundary would be premature.

---

### 2. `WrappingStrategy` as an Invisible Tax
**Current:** `FileSink` defaults to `WrappingStrategy.none`. `HtmlEncoder`
requires `WrappingStrategy.document` to produce valid output. Omitting it
causes a silent failure — broken HTML with no error.

**Root cause:** The encoder and the strategy are not coupled in the API,
but they are coupled in practice. `HtmlEncoder` with `WrappingStrategy.none`
has no valid use case outside of unit tests.

**What we know:** The encoder should declare its required strategy.
The user should not set `WrappingStrategy` manually.

**What we don't know yet:** Whether the right fix is:
  - (A) `HtmlEncoder` sets its required strategy internally
  - (B) A `WrappingEncoder` wrapper that declares strategy
  - (C) `HtmlFileSink` convenience class that encapsulates both
  Option (C) is the least breaking but the least principled.

---

### 3. Theme Has No Single Owner
**Current:** Theme configuration exists in three places:
  - `StyleDecorator(theme:)` — bakes styles into the document
  - `AnsiEncoder(theme:)` — resolves colors during ANSI encoding
  - `HtmlEncoder(theme:)` — resolves colors during HTML encoding

These are inconsistent. A user cannot place a theme in one place and
trust it to propagate. `StyleDecorator` pre-bakes; `AnsiEncoder` and
`HtmlEncoder` resolve lazily and separately.

**What we know:** A `theme` parameter at `Handler` level, propagated
through the pipeline, is the correct end-state.

**What we don't know yet:** The migration path. Removing encoder-level
theme while keeping `StyleDecorator`-level theme would be confusing.
A clean transition requires deprecation + a major version boundary.

---

### 4. `LogSurface` Is Missing from `LogTheme`
**Current:** `HtmlEncoder` infers dark/light mode via a heuristic:
  `debug != LogColor.white → dark`. This breaks for any custom scheme.
  A separate `darkMode: bool?` parameter was added as a workaround.

**What we know:** `LogSurface` (dark/light background context) is
orthogonal to `LogColorScheme` (semantic level colors). They should be
separate fields in `LogTheme`.

**What we don't know yet:** Whether `LogSurface` should be a two-value
enum or whether future rendering targets (e.g., e-ink, high-contrast
accessibility modes) will need more values. Start with `{dark, light}`.

---

### 5. No `lightScheme` Preset
**Current:** `defaultScheme` and `darkScheme` both assume dark terminals
or dark HTML backgrounds. Neither is accessible on a white background.

**What we know:** A `lightScheme` with WCAG-AA compliant hex values is
needed for HTML light mode. The HTML encoder now has a `_lightColorMap`
as a stopgap, but it is encoder-internal and not reachable via `LogTheme`.

**What we don't know yet:** Whether the color map should live in
`LogColorScheme` itself (as a rendering hint per color) or remain in the
encoder as a medium-specific mapping.

---

### 6. Sink Lifecycle Ownership
**Current:** `dispose()` is manually called by the user. For `HtmlEncoder`,
this is mandatory (it writes the JS postamble). Missing it silently
produces broken HTML.

**What we know:** The handler should own its sink's lifecycle. A
`Logger.dispose()` or `LogSession` handle pattern would close the loop.

**What we don't know yet:** How this interacts with long-lived production
loggers where the sink should outlive the configure call. Lifecycle
semantics for persistent vs. ephemeral sinks need more real-world input.

---

### 7. No Beginner Path
**Current:** Every setup requires 4–5 nested concepts assembled correctly.
There is no "zero-decisions" entry point.

**What we know:** A `LogOutput` facade is the right direction.
**What we don't know yet:** The exact API shape. Should it be:
  - `Logger.configure(output: LogOutput.htmlFile('app.html'))`
  - `Logger.get('app').toHtml('app.html')` (fluent)
  - `HtmlLogger.file('app.html')` (factory)
  The first is most consistent with the existing `Logger.configure` API.
