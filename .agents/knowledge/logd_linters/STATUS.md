# logd Linters — Status
> Current as of: logd_linters v0.1.2 | Updated: 2026-07-09

---

## Release State

| Milestone | Status |
|---|---|
| v0.1.0/v0.1.1 — 12 rules, 4 quick-fixes, full integration harness | ✅ Feature-complete, verified clean on core package |
| v0.1.1 — Published to pub.dev | ✅ Published |
| v0.1.2 — 4 additional quick-fixes (8/12 total) | ✅ Complete |
| v0.2.0 — Multi-statement leak audits | 🔲 Not started |
| Workspace-wide `custom_lint` enforcement | 🔲 Not started |

---

## Next Steps (Ordered)

### 1. v0.2.0 — Multi-Statement Checkout/Release Tracing
Upgrade `CheckoutWithoutRelease` to trace checkouts that flow through helper variables across multiple statements, not just single-scope patterns.

### 2. Workspace-Wide custom_lint Enforcement
Enforce custom_lint plugin execution on CI and enable rules by default workspace-wide.

---

## Rules Inventory

| Rule | Group | Quick-Fix? |
|---|---|---|
| `logd_checkout_without_release` | A — Arena Lifecycle | 🔲 |
| `logd_missing_release_in_engine` | A — Arena Lifecycle | ✅ |
| `logd_metadata_set_duplicate` | C — Consumer Usage | ✅ |
| `logd_decorator_not_immutable` | B — Purity & Boundaries | ✅ |
| `logd_formatter_not_immutable` | B — Purity & Boundaries | ✅ |
| `logd_freeze_on_unconfigured_logger` | D — Inheritance Config | 🔲 |
| *(+ 6 more)* | various | 8 of 12 have quick-fixes |

---

## Known Traps

- `dart test` with an empty `void main() {}` does NOT execute custom_lint logic. Always run `dart run custom_lint` in `packages/logd_linters/example/`.
- Pub.dev forbids publishing packages with local path dependencies. Publish `logd_linters` before updating `logd` core's dependency to the hosted version.
- Must publish in order: `logd_linters` first, then `logd` core.
