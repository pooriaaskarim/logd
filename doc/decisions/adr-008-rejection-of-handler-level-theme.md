# ADR-008: Rejection of Handler-Level Theme Parameter and Preservation of Single Source of Truth for Visual Styling

## Status
Accepted (v0.9.7)

## Context
During the design review of the output formatting pipeline, a proposal was evaluated to add a top-level `theme:` parameter directly to `Handler` (e.g., `Handler(theme: LogTheme.dark, ...)`).

The motivation behind the proposal was to simplify theme passing so that `Handler` could automatically configure downstream encoders (`AnsiEncoder`, `HtmlEncoder`) and decorators without requiring an explicit `StyleDecorator`.

However, evaluating this proposal against `logd`'s core architectural principles exposed structural flaws and conflicts with established design rules.

## The Rejected Proposal

```dart
// PROPOSED (REJECTED)
Handler(
  formatter: StructuredFormatter(),
  theme: LogTheme.dark, // <--- Proposed addition to Handler base class
  sink: ConsoleSink(),
);
```

## Rationale for Rejection

1. **Violation of Single Source of Truth (SSOT)**:
   In `logd`'s architecture, visual styling and theming are owned by `StyleDecorator` (which attaches `logd.theme` metadata to `LogDocument` metadata) and/or passed explicitly into specialized encoders (`AnsiEncoder`, `HtmlEncoder`). 
   Adding `theme` to `Handler` creates two competing sources of truth. If a user defines `StyleDecorator(theme: LogTheme.light)` inside `decorators` while supplying `Handler(theme: LogTheme.dark)`, the pipeline suffers from ambiguous, conflicting configuration state.

2. **Violation of Semantic vs. Physical Boundary**:
   `logd` strictly separates **Semantic IR** (`LogDocument`, `LogNode`) from **Physical Rendering** (`TerminalLayout`, `AnsiEncoder`, `HtmlEncoder`). `Handler` is a pure pipeline orchestrator that coordinates `Formatter -> Decorator -> Encoder -> Sink`. It contains no formatting logic or rendering rules. Forcing `Handler` to store visual styling parameters mixes orchestration with visual rendering.

3. **Duplication and Indirection**:
   If `Handler` accepted `theme`, it would have to inspect decorator chains or forcibly override downstream encoder states, adding indirection and hidden behavior. Consumers setting explicit formatters or decorators would find `Handler` mutating or overriding their explicit pipeline setup.

4. **`{Target}Handler` Subclasses Already Resolve DX Needs (ADR-006)**:
   For convenience DX where zero-config themed handlers are desired, `{Target}Handler` subclasses (e.g. `ConsoleHandler`, `HtmlFileHandler`) accept target-specific parameters on their constructors and wire them directly to their internal `StyleDecorator` or `Encoder`. The core `Handler` orchestrator remains clean and unpolluted.

## Decision

1. **`Handler` will NOT accept a `theme:` parameter.** The `Handler` constructor remains strictly focused on pipeline composition (`formatter`, `decorators`, `sink`, `engine`, `filters`).
2. **`StyleDecorator` and Encoders remain the Single Source of Truth for themes.**
   - Document-level theming is attached to semantic IR via `StyleDecorator`.
   - Encoder-level surface or color maps are configured directly on the respective `LogEncoder` (e.g., `AnsiEncoder`, `HtmlEncoder`).
   - Preset `{Target}Handler` subclasses ([ADR-006](adr-006-handler-subclass-convention.md)) encapsulate theme wiring internally for user convenience without leaking theme concerns into the base `Handler` type.

## Consequences

### Positive
- **Architectural Integrity**: `Handler` remains a pure pipeline orchestrator.
- **Single Source of Truth**: Eliminates conflicting theme states between `Handler`, `StyleDecorator`, and Encoders.
- **No Hidden Overrides**: `Handler` never silently overrides decorator or encoder settings.
- **Consistent DX**: `{Target}Handler` subclasses handle convenience parameters cleanly without polluting `Handler`.
