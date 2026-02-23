# Performance Goldens

This directory contains snapshot results of major architectural milestones for the `logd` handler pipeline.

## Performance Ledger (Milestones)

The following table tracks the performance evolution of the `logd` handler architecture through its primary refinement milestones.

| Milestone | Commit | Description | Plain (µs) | Structured (µs) | Json (µs) |
|---|---|---|---|---|---|
| **M0** | `dev` | Legacy Baseline | 276.5 | 467.3 | 26.3* |
| **M1** | `cc3f7ad` | Core Semantic Engine | 198.4 | 569.5 | 274.1 |
| **M2** | `7ed89d8` | Pipeline Migration | 147.5 | 478.7 | 268.1 |
| **M3** | `788b9bb` | Optimized Bitmasks | 138.3 | 405.3 | 241.9 |
| **M4** | `b943c05` | Final Release Candidate | **136.3** | **411.3** | **262.1** |

*\*Legacy JSON utilized raw `jsonEncode` without semantic layout support.*

## Record Artifacts

- [Milestone 0: Legacy Baseline](./milestone_0_legacy_baseline.md)
- [Milestone 1: Semantic Engine](./milestone_1_semantic_engine.md)
- [Milestone 2: Pipeline Migration](./milestone_2_pipeline_migration.md)
- [Milestone 3: Optimized Bitmasks](./milestone_3_optimized_bitmasks.md)
- [Milestone 4: Final Release Candidate](./milestone_4_final_release.md)

## Usage & Maintenance

These snapshots represent the **performance floor**. 

- **Test:** Run `dart run packages/benchmarks/lib/main.dart` and compare against the latest milestone. Investigate any `>10%` throughput regressions.
- **Commit Policy:** Do *not* commit routine benchmarks. Only commit new snapshot records here when:
  - Landing a major architectural/feature milestone
  - Reaching a stable version release
