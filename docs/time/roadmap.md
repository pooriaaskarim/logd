# Time Roadmap

## Database Expansion

### 🟡 P1: Add DST Rules for Additional Regions
**Current Coverage**: North America, Western Europe, parts of Asia/Australia.
**Missing**: South America, Middle East (except Tehran), Africa.

**Action Items**:
- [ ] Add Brazil DST rules (October - February transitions)
- [ ] Add Chile DST rules (varies by year, research current pattern)
- [ ] Add Egypt DST rules (suspended since 2014, fixed offset)
- [ ] Document source for DST rule data (IANA timezone database version)
- [ ] Add validation tests against known historical transitions

**Alternative Approach**: Allow loading rules from JSON configuration file for custom deployments.

---

## Performance

### 🟢 P2: Cache Offset Calculations
**Context**: `_computeOffset` performs date arithmetic on every `Timezone.now` call.

**Current Cost**: ~5-10 date comparisons per call for DST-aware zones.

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

### 🔵 P3: Automated DST Rule Updates
**Context**: Manual updates required when governments change DST policies.

**Long-term Solution**:
- [ ] Research feasibility of IANA tzdata compilation to Dart
- [ ] Evaluate third-party packages (e.g., `timezone` package) integration via optional dependency
- [ ] Create documentation for updating embedded rules

---

## Known Limitations

**Political DST Changes**: Rules reflect 2025 patterns. Updates needed for:
- Russia (abolished DST in 2014)
- Turkey (suspended DST in 2016)
- Brazil (DST observance varies by federal decree)

**Leap Seconds**: Not handled explicitly. Relies on Dart's `DateTime` implementation (which follows POSIX time).

**Historical Dates**: DST rules only accurate for recent years (~2020+). Historical date formatting may be incorrect for dates before rule implementation.
