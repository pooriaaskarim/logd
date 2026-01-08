# Stack Trace Roadmap

## Platform Support

### 🟡 P1: Web Stack Trace Parsing
**Context**: Dart compiled to JavaScript produces different stack formats than VM.

**VM Format**: `#0 function (package:app/file.dart:10:5)`
**Web Formats**:
- Chrome: `at Function (http://localhost/main.dart.js:1234:56)`
- Firefox: `function@http://localhost/main.dart.js:1234:56`
- Safari: `function@http://localhost/main.dart.js:1234:56`

**Implementation**:
- [ ] Add platform detection (check `dart.library.html` vs `dart.library.io`)
- [ ] Define regex patterns for each browser
- [ ] Map JS bundle locations back to Dart source (requires source maps in dev mode)
- [ ] Add browser-specific test suites

---

## Async Handling

### 🟢 P2: Async Boundary Detection
**Context**: Asynchronous stack traces include special frames:
```
#0 asyncFunction (file.dart:10)
<asynchronous suspension>
#1 caller (file.dart:5)
```

**Current Behavior**: Parser may skip the suspension frame incorrectly.

**Proposal**:
- [ ] Detect `<asynchronous suspension>` markers
- [ ] Optionally include both synchronous caller and async origin
- [ ] Add `includeAsyncOrigin` configuration flag
- [ ] Document async frame semantics in architecture doc

---

## Obfuscation

### 🔵 P3: Symbol Deobfuscation
**Context**: Release builds with `--obfuscate` produce mangled names:
```
#0 a.b (file.dart:10)
```

**Blockers**: Requires access to symbol map generated during compilation.

**Future Work**:
- [ ] Research feasibility of embedding symbol map in app
- [ ] Add `SymbolResolver` interface for external deobfuscation services
- [ ] Document manual deobfuscation workflow using `flutter symbolize`

---

## Performance

### 🟢 P2: Lazy Frame Parsing
**Current**: Parser processes frames until first match, already optimized.

**Further Optimization**:
- [ ] Cache regex compilation (currently recreated per call)
- [ ] Benchmark parsing cost on deep stack traces (50+ frames)
- [ ] Consider extracting frame parsing to isolate for expensive operations

---

## Known Limitations

**Format Dependency**: Relies on `StackTrace.toString()` output format. Breaking changes in Dart SDK require parser updates.

**Column Information**: Currently ignored (group 4 in regex). Could be preserved for enhanced error reporting.

**Inline Functions**: Anonymous closures appear as `<fn>` or `<anonymous closure>`, limiting usefulness.
