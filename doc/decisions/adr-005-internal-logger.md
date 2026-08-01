# ADR-005: InternalLogger as Fail-Safe Diagnostics

## Status
Accepted

## Context
When errors occur inside the logging pipeline itself (e.g., a custom `LogSink` fails to write to a full disk, or a configuration validation fails), the logger must not throw exceptions that crash the client application. At the same time, swallowing these errors entirely makes debugging pipeline issues impossible. Standard logging cannot be used to log these internal errors, as that could cause infinite loops.

## Decision
We implement a zero-dependency, fail-safe diagnostic logging utility:
1. We introduce `InternalLogger` to route all internal framework messages, warnings, and errors.
2. `InternalLogger` outputs directly to the platform's diagnostic tools (e.g. standard print or debug stream) bypassing the logd pipeline entirely to prevent circularity.
3. Failures in custom handlers fallback to a safe console print to ensure logs are never silently lost.

## Consequences
- **Pros**: Complete separation between framework-level errors and application-level logging. High reliability and zero chance of infinite recursive logging loops on failure.
- **Cons**: Formatting of internal errors is simpler and less customizable than standard logd output.
