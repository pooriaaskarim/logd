# Logd Output Pipeline: Futuristic API Direction
> Status: Speculative. Requires real-world validation before any implementation.
> These are hypotheses, not commitments. Revisit when logd has more users.

---

## The Guiding Principle

> "Simplicity integrated into complexity."
> The system should embrace the full complexity of its domain, but expose
> only what the user needs to think about at each level of engagement.
> Experts should never be constrained by beginner conveniences.

---

## The Three-Layer API Model

logd should present three coherent engagement levels:

```
Level 1 (Beginner)  → LogOutput facade — zero decisions, sensible defaults
Level 2 (Standard)  → Handler + Sink + Formatter — current API, cleaned up
Level 3 (Expert)    → Full pipeline access — unchanged from today's internals
```

A user enters at Level 1 and graduates to higher levels when their needs exceed
what the facade provides. No level constrains the others.

---

## Level 1: The Facade (LogOutput)

```dart
// Console with color
Logger.get('app').configure(
  output: LogOutput.console(),
);

// HTML file (dark by default)
Logger.get('app').configure(
  output: LogOutput.htmlFile('logs/app.html'),
);

// HTML file, light theme
Logger.get('app').configure(
  output: LogOutput.htmlFile('logs/app.html', theme: LogTheme.light),
);

// Markdown report
Logger.get('app').configure(
  output: LogOutput.markdownFile('logs/report.md'),
);

// Multiple outputs (the common production pattern)
Logger.get('app').configure(
  outputs: [
    LogOutput.console(),
    LogOutput.htmlFile('logs/app.html'),
    LogOutput.jsonFile('logs/app.json.log'),
  ],
);
```

`LogOutput` is a smart builder that:
- Selects the right `LogFormatter` for the target
- Selects the right `LogEncoder` for the target
- Sets the correct `WrappingStrategy` automatically
- Wires the correct `LogSink` with correct defaults
- Never exposes `WrappingStrategy`, `StrategyEngine`, or encoder internals

**Key insight:** `LogOutput` is not a new abstraction — it's a named
constructor factory that produces a correctly configured `Handler`. Experts
can inspect the result.

---

## Level 2: The Cleaned-Up Handler API

For users who need custom decorators, filters, or formatters, the `Handler`
API should remain — but with these cleanups:

### 2a. Theme at the Handler Level
```dart
Handler(
  formatter: StructuredFormatter(),
  theme: LogTheme.dark,          // single source of truth
  decorators: [BoxDecorator()],  // no StyleDecorator needed; theme is automatic
  sink: ConsoleSink(),           // no AnsiEncoder needed; sink knows its renderer
)
```

`Handler.theme` propagates through the pipeline:
- `AnsiEncoder` reads it for color codes
- `HtmlEncoder` reads it for color and surface context
- `StyleDecorator` is no longer needed for basic theming (it may remain for
  document-level style overrides)

### 2b. Encoder Declares Its Strategy
```dart
abstract interface class LogEncoder {
  // NEW: Encoder declares what wrapping it requires.
  // Default: WrappingStrategy.none (unchanged for most encoders)
  WrappingStrategy get requiredStrategy => WrappingStrategy.none;
  ...
}

class HtmlEncoder implements LogEncoder {
  @override
  WrappingStrategy get requiredStrategy => WrappingStrategy.document;
  ...
}
```

`EncodingSink` reads `encoder.requiredStrategy` and honors it automatically.
`WrappingStrategy` disappears from the public API surface.

### 2c. LogTheme Gets LogSurface
```dart
enum LogSurface { dark, light }

class LogTheme {
  const LogTheme({
    required this.colorScheme,
    this.surface = LogSurface.dark,
    this.timestampStyle,
    // ... other style fields unchanged ...
  });

  final LogSurface surface;
  final LogColorScheme colorScheme;
  ...

  static const dark = LogTheme(
    colorScheme: LogColorScheme.darkScheme,
    surface: LogSurface.dark,
  );

  static const light = LogTheme(
    colorScheme: LogColorScheme.lightScheme,
    surface: LogSurface.light,
  );
}
```

`HtmlEncoder` reads `theme.surface` — no more `darkMode` parameter.
`AnsiEncoder` ignores `theme.surface` — terminal owns its own background.

### 2d. LogColorScheme Gets lightScheme
```dart
static const lightScheme = LogColorScheme(
  trace:   LogColor.green,
  debug:   LogColor.brightBlack,  // dark slate, readable on white
  info:    LogColor.blue,
  warning: LogColor.yellow,
  error:   LogColor.red,
);
```

---

## Level 3: Full Expert Access (Unchanged Internals)

The internal pipeline — `LogDocument`, `LogNode`, `TerminalLayout`,
`LogPipelineFactory`, `ArenaEngine` — remains unchanged. Experts who need
to write custom formatters, custom encoders, or custom sinks continue to
work at this level without any impedance from the higher-level facades.

---

## What Must NOT Be Designed Yet

These are known unknowns. Designing them now would be premature.

| Question | Why We Can't Answer It Yet |
|---|---|
| Should `LogOutput` live in a separate package? | Unknown how heavy logd's dependency tree will grow |
| Should `Handler.theme` replace `StyleDecorator` entirely? | Need to understand real use cases for document-level style overrides |
| Should `Logger.dispose()` exist? | Need real-world lifecycle patterns from non-trivial apps |
| Should `LogSurface` be a two-value enum or richer? | Accessibility modes (high-contrast, e-ink) unknown |
| Should a fluent builder be offered alongside `Handler`? | Need more user feedback on which configuration style feels natural |
| How should `LogOutput` handle rotation and advanced FileSink options? | Requires more real production app patterns as reference |

---

## Migration Philosophy

> Critique now. Design when the dust settles. Migrate without breaking.

All changes to the public API should follow this discipline:
1. **Deprecate, don't remove.** `darkMode` on `HtmlEncoder` should be
   deprecated with a clear message pointing to `theme.surface`, then
   removed in a major version boundary.
2. **Additive first.** `LogSurface`, `lightScheme`, `LogTheme.light/dark`
   static constants — all purely additive. Ship these first.
3. **Facade after validation.** `LogOutput` should only ship after its
   API shape has been validated against at least 2–3 real production use
   cases. Premature facades calcify the wrong model.
4. **Never collapse the pipeline.** The Formatter → Decorator → Encoder
   separation must remain accessible at all times. The facade is a layer
   above it, not a replacement for it.

---

## Philosophical Design Principles

### Principle 1: Surface-Medium Orthogonality
A common design flaw in logging themes is conflating the *colors of the log levels* (e.g. "what color is an info log?") with the *canvas background on which they are printed* (e.g. "is the background black or white?").
- **Terminals** are self-governing surfaces. The terminal emulator maps ANSI codes (`\e[34m` for blue) onto its user-configured palette. Therefore, `AnsiEncoder` remains surface-agnostic.
- **Files** (HTML, Markdown, PDF) are controlled surfaces. The encoder decides the background.
We decouple these via the `LogSurface` configuration. A theme describes the semantic palette, and specifies its target `LogSurface` (dark/light). The rendering encoder uses the surface context to determine CSS backgrounds, border colors, and badge texts, keeping the core formatting logic pure and medium-agnostic.

### Principle 2: Self-Declaring Modularity (Encapsulation of Wrapping)
Modularity should not require explicit coordination by the developer. Under the current API, developers must manually align the encoder's structure (e.g. `HtmlEncoder` requiring `preamble`/`postamble`) with the sink's wrapping strategy (`WrappingStrategy.document`). This leaks implementation details.
In our future vision, encoders declare their own structural wrapper constraints (`requiredStrategy`). Sinks inspect this field and configure the file pipeline automatically. The user registers the encoder, and the system resolves the necessary wrapping implicitly, integrating simplicity into the underlying complexity.

### Principle 3: Lifecycle Safety & Clean Teardown
Sinks that write complex file types (such as HTML or XML) require deterministic finalization to inject closing structures (e.g. `postamble()` for scripts and closing tags).
If loggers are global singletons, their lifecycle is indefinite. Deleting or disposing the sink manually creates a race condition where subsequent logging calls write to a disposed handle.
We must transition to a **Session/Handle** pattern where the logger config returns a closeable session handle that manages teardown atomically, ensuring all files are correctly flushed, finalized, and locked.

