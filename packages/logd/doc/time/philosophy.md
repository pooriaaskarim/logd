# Time Design Philosophy

## Strategic Dependencies

**Principle**: Minimize core dependencies, but leverage industry standards for complex domains.

**Rationale**: While `logd` aims for minimal dependencies, Timezone resolution (especially DST handling) is politically complex and constantly changing. Implementing a custom engine was fragile and maintenance-heavy.
- **Decision**: Adopt `package:timezone` (IANA database).
- **Benefit**: Ensures correctness and simplifies the codebase.
- **Mitigation**: The dependency is wrapped in `logd`'s API, shielding users from breaking changes in the underlying package.

## Standardized Timezone Handling

**Principle**: Use the standard IANA Time Zone Database.

**Rationale**: System timezone data varies by OS version and platform (especially on Android). Using the bundled IANA database ensures:
- **Consistency**: Identical output for the same UTC instant across different hosts.
- **Reproducibility**: Formatting in tests is deterministic regardless of the machine's locale or OS version.
- **Accuracy**: Automatic updates via package version bumps when governments change DST rules.

**Limitation**: Requires loading the database (handled automatically via `ensureInitialized` or implicit initialization).

## Microsecond Precision

**Principle**: Support sub-millisecond timestamp resolution.

**Implementation**: Format tokens `SSS` (milliseconds) and `FFF` (microseconds) provide up to 6 decimal places of precision.

**Use Case**: High-frequency event logging where multiple events occur within 1ms. Necessary for debugging race conditions and analyzing performance bottlenecks.
