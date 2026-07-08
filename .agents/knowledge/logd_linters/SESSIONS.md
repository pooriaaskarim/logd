# logd Linters — Session Log
> Append-only. Each entry records what was attempted, what broke, and what was learned.
> Never edit past entries. Add new entries at the top.

---

## 2026-07-03 | v0.1.0-RC | Initial Rules Implementation & Integration Test Harness

### What We Did
- Implemented initial 12 AST rules covering Arena lifecycle, package purity, engine config, and logger inheritance.
- Created `packages/logd_linters/example/` integration package containing target files with annotated expectations (`// expect_lint: rule_name`).
- Added 4 initial `DartFix` quick-fixes.
- Integrated `custom_lint` plugin harness to execute rules during static analysis.

### Bugs Hit
1. **The Scope Stack Bug**: An initial implementation of `CheckoutWithoutRelease` used a simple flat map of declarations within the visitor. This triggered false positives when exiting nested block functions or closures, because the visitor exited helper callbacks and prematurely cleared the main function registry.
   - **Fix**: Replaced the flat map with a structured Lexical Scope Stack (`List<Map<String, MethodInvocation>>`).
2. **Left-Hand-Side Element Resolution Issue**: In analyzer 8.x, simple identifiers on the LHS of assignments (e.g. `_lastDoc = document`) returned `null` for `.element`.
   - **Fix**: Used `node.writeElement ?? left.element` and resolved `PropertyAccessorElement` to its inducing variable to correctly detect document retention.
3. **Ghost vs. Configured Freeze False Positives**: `logd_freeze_on_unconfigured_logger` had no way of knowing if a logger was configured in preceding statements.
   - **Fix**: Walked back the enclosing block statement chain to look for static `Logger.configure(name, ...)` matching the target logger name.

### Decisions Explicitly Deferred
- Implementing the remaining 8 quick-fixes deferred to v0.2.0.
- Deep tracking of checkouts passed as parameters to helper methods (kept scoping simple to minimize false-positives).
