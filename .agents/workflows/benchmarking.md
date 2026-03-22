---
description: Run logd benchmarks and persist the results with system context
---

# Benchmark & Persist Workflow

This workflow automates capturing `logd` logging performance against the current system state, enabling regression tracking.

## 1. Execute Benchmark and Persist

// turbo
1. Run the benchmarks and save them alongside the environment context:
```bash
cd packages/benchmarks
export OUT="records/benchmark_$(date +%Y%m%d_%H%M%S).md"

echo "# Benchmark Report" > $OUT
echo "**Commit:** $(git log -n 1 --oneline)" >> $OUT
echo "**Branch:** $(git rev-parse --abbrev-ref HEAD)" >> $OUT
echo "**Dart:** $(dart --version 2>&1)" >> $OUT
echo -e "\n\`\`\`text" >> $OUT
dart run lib/main.dart >> $OUT
echo "\`\`\`" >> $OUT

echo "Saved to packages/benchmarks/$OUT"
```

## 2. Compare Results
1. Read the newly generated `$OUT` file.
2. Quickly compare factors and throughputs against the most recent historical baseline in `packages/benchmarks/records/` and report any significant deviances to the user.
