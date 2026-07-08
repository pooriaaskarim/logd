# logd Linters — Architecture
> Stable reference. Implementation patterns and invariants for writing and testing custom lint rules.
> Update only when a structural pattern is permanently resolved.

---

## Rule Groups (Mirrors logd Core Boundaries)

```
Group A — Arena & Lifecycle     → Prevents memory leaks and stale document reads
Group B — Purity & Boundaries   → Enforces Semantic vs Physical layer decoupling
Group C — Consumer Usage        → Prevents misconfigured engine and metadata patterns
Group D — Inheritance Config    → Prevents ghost logger nodes and config pollution
```

---

## AST Visitor Patterns

### Lexical Scope Stack (for lifecycle rules)

Rules like `logd_checkout_without_release` require matching checkout calls to release calls. A naive flat visitor causes false positives in nested closures/blocks.

**Solution:** Custom `RecursiveAstVisitor` managing a `List<Map<String, MethodInvocation>>` scope stack.
- `visitBlockFunctionBody` / `visitExpressionFunctionBody` → push new scope
- Checkout calls register to the innermost scope
- `release` / `releaseRecursive` calls look inward-outward to remove registrations
- Exiting a function body pops the scope and reports any remaining unreleased checkouts

### LHS Assignment Resolution (analyzer 8.x gotcha)

Simple identifiers on the left side of assignments do not resolve `element` directly — it returns `null`.

**Solution:** `node.writeElement ?? left.element`. Then resolve `PropertyAccessorElement` to its variable via `element.variable` to detect field-level document retention (`_lastDoc = document`).

### Intervening Statement Matching (for `logd_freeze_on_unconfigured_logger`)

To distinguish a correctly configured freeze from a ghost-logger freeze:
- Access the enclosing block statement chain
- Walk back through all preceding statements in the same block
- Check if any is a static invocation of `Logger.configure(name, ...)` where `name` matches the logger being frozen

---

## Integration Testing Harness

Standard `dart test` does not execute custom_lint logic. Rule verification requires a dedicated consumer package at `packages/logd_linters/example/`.

### Setup
```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.8.1
  logd_linters:
    path: ../
```
```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
```

### Writing Violation Tests
Mark expected violations with a directive comment on the preceding line:
```dart
// expect_lint: logd_checkout_without_release
final doc = factory.checkoutDocument(); // never released
```

### Running
```bash
dart run custom_lint
```

---

## Publishing Checklist

Packages must be published in order. Pub.dev forbids local path `dev_dependencies`.

### Step 1 — Verify
```bash
cd packages/logd_linters
dart analyze .
dart format --output=none --set-exit-if-changed .
dart pub publish --dry-run
```

### Step 2 — Publish `logd_linters`
```bash
dart pub publish
```

### Step 3 — Update `logd` core
In `packages/logd/pubspec.yaml`:
```diff
 logd_linters:
-  path: ../logd_linters
+  ^0.1.0
```
Verify: `dart pub get && dart run custom_lint`

### Step 4 — Branch & PR
```bash
git push origin feat/logd-linters
# Open PR: feat/logd-linters → dev
# CI must pass before merge
```

### Step 5 — Release to master
```bash
git checkout dev && git pull
dart pub publish --dry-run   # final check
# Open PR: dev → master
# After merge:
git checkout master && git pull
git tag -a v0.1.0 -m "Release logd_linters v0.1.0"
git push origin v0.1.0
dart pub publish
```

---

## Design Principles

1. **Semantic vs Physical Boundary:** Formatters and decorators operate strictly on `LogDocument`. No rule should allow direct `stdout`/`stderr` interaction inside formatters/decorators.
2. **Statelessness & Immutability:** Formatters and decorators must be `@immutable`. Under isolate-based logging, these instances are shared across worker isolates — mutable state creates data races.
