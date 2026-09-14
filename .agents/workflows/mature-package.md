# Mature Satellite Package Workflow

Use this workflow to systematically mature and productionize satellite packages (e.g., `logd_html`, `logd_sqlite`) extracted from the `logd` core. This ensures parity, stability, and proper cross-isolate serialization across all extensions.

## Phase 1: Core Alignment & Registry Validation
- [ ] **Serialization Audit:** Ensure the package correctly implements `registerLogd[Name]Serializers()` and calls `LoggerSerializationRegistry.ensureInitialized()` *before* registering its own components.
- [ ] **Shim Verification:** Verify that `logd` core's deprecated shims correctly map to the new package, and that `hide` clauses are used during testing to avoid type collisions.
- [ ] **API Surface Review:** Ensure all public classes, formatters, encoders, and handlers follow `logd` naming and immutability standards.

## Phase 2: Code Hardening & Edge Case Fortification
- [ ] **Type Coercion:** Fortify `LogEntry.context` parsing (and similar fields) to gracefully handle non-map objects or raw strings.
- [ ] **Escaping & Injection Safety:** Ensure payloads are properly sanitized for the target (e.g., strict HTML escaping, Markdown syntax safety, SQLite injection prevention).
- [ ] **Null Handling:** Ensure formatting dialects gracefully handle missing metadata or null fields predictably.

## Phase 3: The 4-Pillar Testing Matrix
Ensure the package has a `test/` directory covering:
- [ ] **Serialization Tests:** Full round-trip validation proving that deep configuration properties survive JSON serialization across isolate boundaries.
- [ ] **Encoder/Formatter Tests:** Pure, isolated tests for specific output formatting, testing all dialects and schema/header combinations.
- [ ] **Handler Integration Tests:** End-to-end tests proving synchronous and asynchronous (`Isolate`) execution using temporary sandboxes or mock servers.
- [ ] **Edge Case Tests:** Explicitly testing malformed inputs, extreme depth clamping, and invalid configurations.

## Phase 4: Standardized Documentation (`doc/`)
Ensure the package contains a `doc/` directory with:
- [ ] `architecture.md`: Explains the specific pipeline lifecycle and design limitations.
- [ ] `migration_guide.md`: Maps out breaking changes and transitioning from `logd` core v0.9.6.
- [ ] `benchmarks.md`: Highlights throughput and memory allocation profiles.
- [ ] (Optional) Feature-specific docs (e.g., `dialects.md`, `database_schema.md`).

## Phase 5: Applied Examples (`example/`)
- [ ] `example/main.dart`: A clean, single-file standard usage script.
- [ ] `example/extra/`: 2-3 advanced, real-world examples specific to the package (e.g., schema evolution, file rotation, custom CSS injection).

## Phase 6: Release Polish
- [ ] Update `CHANGELOG.md` with explicit notes on the maturation process.
- [ ] Ensure `dart format .` and `dart analyze` pass.
- [ ] Run `dart test` to verify complete green status.
