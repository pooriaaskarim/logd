# ADR-006: `{Target}Handler` Subclass Convention for Ecosystem-Wide DX

## Context

As logd's feature set matured through v0.9.x, two related pressures emerged:

1. **Beginner DX gap**: Constructing a `Handler` for common targets (console, HTML file,
   JSON file, SQLite) requires correctly composing 4–5 concepts — `LogFormatter`,
   `LogDecorator`, `LogEncoder`, `LogSink`, and `WrappingStrategy` — each with its own
   defaults and non-obvious interdependencies. The `HtmlEncoder` + `FileSink` silent failure
   (broken HTML when `WrappingStrategy.document` is omitted) is the canonical symptom.

2. **Satellite scaling problem**: The project is an expanding monorepo. `logd_sqlite` is
   already published. `logd_sentry`, `logd_flutter`, `logd_opentelemetry`, a Markdown
   handler, and an HTML `HttpSink` handler are planned. Each satellite needs to expose a
   user-facing entry point consistent with core's DX improvements.

## The Debate

**Option A — `LogOutput` Facade (previously planned as `v0.9.3`)**

A new named-constructor factory class that builds a correct `Handler` for standard targets:
`LogOutput.console()`, `LogOutput.htmlFile(path)`, `LogOutput.sqlite(path)`.

- ✅ Non-breaking. Existing `Handler`-based code is untouched.
- ✅ Solves the beginner path for core-known targets immediately.
- ❌ Introduces a second concept alongside `Handler`. New users encounter both and must choose.
- ❌ Does not scale to satellite packages. Each satellite is in a separate package and
  cannot add a named constructor to `LogOutput` in `logd` core. The satellite would need
  its own convention (`SqliteOutput.handler(...)`, `SentryOutput.handler(...)`), producing
  an inconsistent, fragmented ecosystem.
- ❌ `LogOutput` is a factory that returns a `Handler` — experts inspecting the result see
  the raw pipeline anyway, undermining the abstraction.

**Option B — Named constructors directly on `Handler`**

Add `Handler.console()`, `Handler.htmlFile(path)`, `Handler.jsonFile(path)` as named
constructors on the core `Handler` class itself.

- ✅ Zero new concept surface — everything is still a `Handler`.
- ✅ Discoverable via autocomplete on a class users already know.
- ❌ Satellite packages cannot add named constructors to a foreign class. The same
  asymmetry problem as Option A — satellites would still need a different pattern.
- ❌ The `Handler` constructor list grows unboundedly as new targets are introduced.

**Option C — `{Target}Handler` Subclasses (Chosen)**

A `{Target}Handler extends Handler` subclass for each output target. Core ships
`ConsoleHandler`, `HtmlFileHandler`, `JsonFileHandler`, `PlainFileHandler`.
Each satellite ships its own (e.g., `SqliteHandler` in `logd_sqlite`,
`SentryHandler` in `logd_sentry`).

- ✅ A single, universally applicable pattern across core and all satellite packages.
- ✅ The ecosystem scales without coordination. Each package owns its subclass.
- ✅ The type system stays flat — every convenience class is still a `Handler`, composable
  with `AsyncHandler`, `MultiSink`, filters, and decorators without friction.
- ✅ `AsyncHandler extends Handler` is already a proven precedent within the codebase.
- ✅ Discoverability is direct: `ConsoleHandler`, `SqliteHandler` are immediately
  identifiable via IDE autocomplete without requiring knowledge of `Handler` first.
- ❌ Core ships four new classes instead of four named constructors. The class count
  increases, but each class is thin and carries no logic beyond wiring its pipeline.

## Decision

We adopt the **`{Target}Handler` subclass convention** as the single pattern for
exposing opinionated, pre-wired logging pipelines to users across the entire logd ecosystem.

**Naming convention**: `{OutputTarget}Handler` — e.g., `ConsoleHandler`,
`HtmlFileHandler`, `JsonFileHandler`, `PlainFileHandler`, `SqliteHandler`, `SentryHandler`.

**Implementation rules**:
1. Every `{Target}Handler` must extend `Handler` and be `@immutable`.
2. Every `{Target}Handler` must supply sensible defaults for its formatter, decorators,
   and sink. Users should be able to call `ConsoleHandler()` with zero arguments and get
   correct, styled output.
3. All user-facing parameters (theme, log level, path, capacity) are exposed on the
   subclass constructor. The underlying `Handler` parameters (`formatter`, `decorators`,
   `sink`, `engine`, `filters`) remain available on `Handler` itself for expert overrides.
4. The `LogOutput` facade concept is **withdrawn**. References to it in roadmaps,
   planning documents, and changelogs are superseded by this ADR.
5. The raw `Handler(formatter: ..., sink: ...)` constructor remains the expert-level API
   and is never removed. Subclasses are a convenience layer, not a replacement.

## Rationale

The satellite scaling argument is decisive. Any pattern that leaves satellite packages
unable to match core's DX conventions produces an inconsistent ecosystem — the worst
outcome for a library whose value proposition is coherent, modular logging. The subclass
approach eliminates this problem structurally, at the cost of a thin class per output target
(which carries zero runtime overhead). The precedent of `AsyncHandler extends Handler`
confirms the approach already fits the project's idiom.

This also aligns with **Predictable Silence** (from the Vault Manifest): the user who
writes `ConsoleHandler()` gets exactly what the name says. There is no invisible tax
from misconfigured wrapping strategies or mismatched encoder/sink pairs. The subclass
encapsulates the correct wiring as a compile-time guarantee.

## Consequences

- **Positive**: A universally consistent API shape across core and all satellite packages.
  Users learn one pattern (`{Target}Handler()`) and apply it everywhere. Every convenience
  class is fully inspectable as a `Handler`, composable with `AsyncHandler` and filters.
- **Positive**: The `HtmlEncoder` + `WrappingStrategy` silent failure is eliminated by
  construction — `HtmlFileHandler` wires the correct strategy internally.
- **Positive**: The `LogOutput` facade plan is cleanly withdrawn before any implementation
  effort is spent on it.
- **Negative**: Core ships four new classes instead of zero (Option B adds named
  constructors, not classes). Each is a thin wrapper, but the class count increases.
- **Negative**: Until the convenience subclasses are shipped, the beginner DX gap persists.
  This is a conscious deferral, not a regression.

---
*Status: Accepted*
*Date: 2026-08-11*
