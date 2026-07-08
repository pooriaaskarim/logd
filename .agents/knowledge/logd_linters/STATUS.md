# logd Linters — Status
> Current as of: logd_linters v0.1.0-RC | Updated: 2026-07-08

---

## Release State

| Milestone | Status |
|---|---|
| v0.1.0 — 12 rules, 4 quick-fixes, full integration harness | ✅ Feature-complete, verified clean on core package |
| v0.1.0 — Published to pub.dev | 🔲 Not yet done |
| v0.2.0 — Remaining 8 quick-fixes | 🔲 Not started |
| v0.2.0 — Multi-statement leak audits | 🔲 Not started |
| Workspace-wide `custom_lint` enforcement | 🔲 Not started |

---

## Next Steps (Ordered)

### 1. Publish v0.1.0 to pub.dev

Run in `packages/logd_linters`:
```bash
dart analyze .
dart format --output=none --set-exit-if-changed .
dart pub publish --dry-run
```
Then publish `logd_linters` first, then update `logd` core `pubspec.yaml`:
```diff
 logd_linters:
-  path: ../logd_linters
+  ^0.1.0
```
Full checklist → see ARCHITECTURE.md § Publishing Checklist.

### 2. v0.2.0 Quick-Fixes (after v0.1.0 is live)
- `logd_metadata_set_duplicate` — remove duplicate items from set literals
- `logd_missing_release_in_engine` — wrap body in `try-finally`, insert `releaseRecursive`
- `logd_decorator_not_immutable` — prepend `@immutable`, convert non-final fields
- `logd_formatter_not_immutable` — same as above

### 3. Multi-Statement Checkout/Release Tracing
Upgrade `CheckoutWithoutRelease` to trace checkouts that flow through helper variables across multiple statements, not just single-scope patterns.

---

## Rules Inventory

| Rule | Group | Quick-Fix? |
|---|---|---|
| `logd_checkout_without_release` | A — Arena Lifecycle | 🔲 |
| `logd_missing_release_in_engine` | A — Arena Lifecycle | 🔲 |
| `logd_metadata_set_duplicate` | C — Consumer Usage | 🔲 |
| `logd_decorator_not_immutable` | B — Purity & Boundaries | 🔲 |
| `logd_formatter_not_immutable` | B — Purity & Boundaries | 🔲 |
| `logd_freeze_on_unconfigured_logger` | D — Inheritance Config | 🔲 |
| *(+ 6 more)* | various | 4 of 12 have quick-fixes |

---

## Known Traps

- `dart test` with an empty `void main() {}` does NOT execute custom_lint logic. Always run `dart run custom_lint` in `packages/logd_linters/example/`.
- Pub.dev forbids publishing packages with local path dependencies. Publish `logd_linters` before updating `logd` core's dependency to the hosted version.
- Must publish in order: `logd_linters` first, then `logd` core.
