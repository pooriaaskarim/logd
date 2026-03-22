---
trigger: always_on
---

# Agent Code Style & Efficiency

As an agentic assistant (Antigravity), follow these specific patterns to maintain codebase consistency and tool-calling efficiency:

## 1. Library Patterns
- **Immutability**: All formatters, decorators, and metadata configurations must be `@immutable`. Use `final` fields exclusively.
  - **⚠️ Arena Exception (`arena_refinement` branch)**: `LogDocument` and all `LogNode` subclasses deliberately drop `@immutable` to support the LIFO pool. They gain `reset()` and `releaseRecursive()` methods. Formatters, decorators, and metadata configs remain `@immutable`. Arena-owned documents **must not** be retained past the log cycle.
- **Bitmasks**: `LogTag` must be handled as an `int` bitmask. Use bitwise operations (`&`, `|`, `~`) instead of `Set` methods.
- **Semantic Metadata**: Use `Set<LogMetadata>` for user-facing configuration of what data to include in a log.
- **Trailing Commas**: Always use trailing commas for argument lists and collection literals to satisfy `require_trailing_commas`.

## 2. Tool Efficiency
- **Formatting**: Use `dart format .` via `run_command` only once at the end of a bulk edit phase. Do not invoke formatting tools for every single file edit unless explicitly requested by the user.
- **Linting**: If `dart analyze` reports issues after an edit, fix only the logical errors or high-severity lints. Do not perform exhaustive "chore" cleanup unless directed.