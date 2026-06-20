# Time Roadmap

## Database Expansion

### ✅ P1: Add DST Rules for Additional Regions
**Status**: Completed via adoption of `package:timezone`.

**Outcome**:
- Full IANA Time Zone Database support is now available.
- Regions like Brazil, Chile, Egypt, etc., are all supported out-of-the-box.
- No manual rule entry required.

---

## Performance

### 🟢 P2: Cache Offset Calculations
**Context**: `_computeOffset` performs date arithmetic on every `Timezone.now` call.

**Current Cost**: Minimal, as `package:timezone` uses optimized lookups, but `Timezone.offset` still does a lookup.

**Optimization**:
- [ ] Cache computed offset with 1-minute granularity
- [ ] Invalidate cache on minute boundary or explicit timezone change
- [ ] Benchmark improvement on high-frequency logging (target: 50% reduction)

**Implementation**: Add `_offsetCache` map with `(DateTime.minute, Duration)` entries.

---

## API Enhancements

### 🟢 P2: Date-Only Formatting
**Context**: Some use cases need only date part without time.

**Proposal**:
- [ ] Add `Timestamp.dateOnly(pattern)` factory
- [ ] Optimize by skipping time-related token parsing
- [ ] Common patterns: `yyyy-MM-dd`, `dd/MM/yyyy`

---

## Maintenance

### ✅ P3: Automated DST Rule Updates
**Status**: Completed via adoption of `package:timezone`.

**Solution**:
- Library updates to `logd` will bump `timezone` package version.
- Users verify accurate rules based on `timezone` version.

### ✅ P1: IOS Timezone name resolution corrupted
**Status**: Completed (v0.8.1).
**Context**: IOS platform-based timezone fetch was flaky and sandboxed. Resolved by using `DateTime.now().timeZoneName` as the primary process-free source on iOS.

### ✅ P1: Windows Timezone name resolution failure
**Status**: Completed (v0.8.3).
**Context**: On Windows, the system timezone names (e.g. `'Iran Standard Time'`) were not recognized by standard IANA databases, resulting in location exceptions. Resolved by embedding a Unicode CLDR mapping table to translate Windows timezone names to standard IANA timezone identifiers.

---

## Known Limitations

## Known Limitations

**Leap Seconds**: Not handled explicitly. Relies on Dart's `DateTime` implementation (which follows POSIX time).

