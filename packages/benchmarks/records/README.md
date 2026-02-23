# Performance Goldens

This directory contains snapshot results of major architectural milestones for the `logd` handler pipeline.

## Milestone History

| Date | File | Description |
|---|---|---|
| Feb 2026 | [legacy_system_baseline.md](./legacy_system_baseline.md) | **Phase 0 Baseline**. Performance before the semantic document IR migration. |
| Feb 2026 | [2026_02_semantic_migration_milestone.md](./2026_02_semantic_migration_milestone.md) | **Phase F Migration Complete**. Verified perfectly flat MultiSink scaling and native semantic throughput. |
| Feb 2026 | [benchmark_pre_bitmask.md](./benchmark_pre_bitmask.md) | Baseline immediately prior to the `Set<LogTag>` -> `int` bitmask performance migration. |

## Usage & Maintenance

These snapshots represent the **performance floor**. 

- **Test:** Run `dart run packages/benchmarks/lib/main.dart` and compare against the latest milestone. Investigate any `>10%` throughput regressions.
- **Commit Policy:** Do *not* commit routine benchmarks. Only commit new snapshot records here when:
  - Landing a major architectural/feature milestone
  - Reaching a stable version release
