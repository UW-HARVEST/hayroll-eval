# Quick Start Guide for Evaluators

## Prerequisites

Before running the evaluation, ensure you have:
- `bear`, `make`, `gcc`, `cargo`, `python3` installed
- Hayroll installed at `~/Hayroll/hayroll` (or set `export HAYROLL_PATH=/path/to/hayroll`)

## One-Command Evaluation

```bash
cd /home/hurrypeng/inariroll-tests
./run_evaluation.bash
```

**Runtime:** XXX hours (first run with full CRUST evaluation)

---

## Output Files

### Step 1: Dependencies & Download
- Verifies all tools are available
- Downloads benchmarks if missing (CRUST zip + libmcs/zlib git repos)

### Step 2: CRUST Evaluation
```
benchmark_summary.json              (pass/fail per project)
metadata.json                       (auto-discovered test metadata)
metadata-filtered.json              (only passing projects)
aggregated_statistics.json          (macro translation stats)
aggregated_performance.json         (pipeline stage timing)
```

### Step 3: libmcs Evaluation
```
libmcs/aggregated_statistics_libmcs.json
libmcs/aggregated_performance_libmcs.json
```

### Step 4: zlib Evaluation
```
zlib/aggregated_statistics_zlib.json
zlib/aggregated_performance_zlib.json
```

### Step 5: Final Tables (The Main Output)
```
outcome_table.tex                   CRUST translation outcomes
outcome_table_libmcs.tex            libmcs translation outcomes
outcome_table_zlib.tex              zlib translation outcomes
performance_table.tex               Performance comparison (all 3)
failing_table.tex                   Macro rejection reasons (all 3)
```

---

## Final Deliverables

The 5 LaTeX files above are the main outputs for your paper. Include them as:

```latex
\input{outcome_table.tex}
\input{performance_table.tex}
\input{failing_table.tex}
```

**Note:** The table column headers currently show "Placeholder 1/2/3". You can manually replace with "CRUST", "libmcs", "zlib" in the generated `.tex` files before including them.
