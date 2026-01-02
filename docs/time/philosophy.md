# Time Design Philosophy

## Dependency Isolation

**Principle**: Avoid external dependencies for core timestamp functionality.

**Rationale**: As a foundational library, `logd` must minimize dependency conflicts. External packages like `intl` or `timezone` have their own versioning constraints that would propagate to all `logd` users. The custom implementation ensures:
- Zero version conflicts
- Reduced total dependency graph size
- Predictable behavior across platforms

**Trade-off**: Requires maintaining custom formatters and timezone rules.

## Explicit Timezone Handling

**Principle**: Use rule-based DST calculation rather than system timezone databases.

**Rationale**: System timezone data varies by OS version and platform. Embedding common DST rules ensures:
- Consistent output for the same UTC instant across different hosts
- Reproducible timestamp formatting in test environments
- Explicit control over timezone transitions

**Limitation**: Political changes to DST rules require library updates or manual configuration via `Timezone()` factory.

## Microsecond Precision

**Principle**: Support sub-millisecond timestamp resolution.

**Implementation**: Format tokens `SSS` (milliseconds) and `FFF` (microseconds) provide up to 6 decimal places of precision.

**Use Case**: High-frequency event logging where multiple events occur within 1ms. Necessary for debugging race conditions and analyzing performance bottlenecks.
