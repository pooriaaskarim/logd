# Performance Goldens

This directory contains snapshot results of major architectural milestones for the `logd` handler pipeline.

## Milestone History

| Date | File | Description |
|---|---|---|
| Feb 2026 | [legacy_system_baseline.txt](./legacy_system_baseline.txt) | **Phase 0 Baseline**. Performance before the semantic document IR migration. |
| Feb 2026 | [2026-02_semantic_migration_milestone.txt](./2026-02_semantic_migration_milestone.txt) | **Phase F Migration Complete**. Verified perfectly flat MultiSink scaling and native semantic throughput. |

## Usage for Regression Testing

These files serve as a **performance floor**. During future development:
1. Run benchmarks via `dart run packages/logd_benchmarks/lib/main.dart`.
2. Compare results (specifically the percentages and factors) against the latest milestone.
3. If a change causes a significant regression (e.g., >10% slowdown in `PlainFormatter` or non-flat scaling in `MultiSink`), investigate for architectural drift.

## Maintenance

Do NOT commit every benchmark run here. Only commit a new file when:
- A major feature is added (e.g., a new complex Formatter).
- A significant intentional optimization is merged.
- The project reaches a new stable release version.

For routine commits, rely on Git history to track micro-fluctuations in these files.
