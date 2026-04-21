# Hayroll Evaluation Pipeline

This guide explains how to run the complete evaluation pipeline for all three benchmarks (CRUST-Bench, libmcs, zlib) and generate the LaTeX tables in the paper.

## Files

### Main Scripts
- **`setup.bash`**: One-stop setup: clones and builds Hayroll, then downloads all benchmarks
- **`run_evaluation.bash`**: Master orchestration script (runs everything)
- **`build-docker.bash`**: Builds the Docker evaluation image
- **`Dockerfile`**: Container image definition

### Benchmark-Specific Patch Files
- **`libmcs_patch/`**: libmcs tests adapted from OpenLibm and test harness
- **`zlib_patch/`**: zlib test harness

### CRUST-specific scripts
- **`benchmark_crust.py`**: CRUST full evaluation
- **`generate_metadata_crust.py`**: Generates metadata for CRUST projects
- **`filter_failing_metadata_crust.py`**: Filters out failed CRUST projects
- **`analyze_crust.py`**: Analyzes CRUST pass rate

### Aggregate scripts
- **`aggregate_reports_crust.py`**: Aggregates CRUST statistics and performance data
- **`aggregate_reports_libmcs.py`**: Aggregates libmcs statistics and performance data
- **`aggregate_reports_zlib.py`**: Aggregates zlib statistics and performance data
- **`generate_outcome_table.py`**: Generates translation outcome tables
- **`generate_performance_table.py`**: Generates performance comparison table
- **`generate_failing_table.py`**: Generates macro rejection reasons table

## Quick Start

```bash
./setup.bash          # fetch, build Hayroll and download benchmarks, NOT NEEDED FOR PRE-BUILT DOCKER IMAGE
./run_evaluation.bash # run full evaluation
```

`setup.bash` will:
1. Clone Hayroll at the pinned version into `Hayroll/` (pass `--latest` to track `main` instead)
2. Build Hayroll (runs its own `prerequisites.bash` and `build.bash`)
3. Download benchmarks into `./CBench`, `./libmcs`, and `./zlib`
4. Overlay local patch files from `libmcs_patch/` and `zlib_patch/` onto the fetched git repositories

`run_evaluation.bash` will:
1. Check all dependencies (bear, make, gcc, cargo, python3, Hayroll)
2. Run all tests for CRUST-Bench, libmcs, and zlib
3. Aggregate results and generate LaTeX tables

It should take fewer than 25 minutes to run everything. Reference: Intel(R) Core(TM) i7-1370P CPU @ 1.90GHz × 14, 64GB RAM, on a poorly radiated machine.

## Docker

A self-contained image is provided so the pipeline can be reproduced without installing anything on the host (benchmarks and Hayroll are baked in at build time, so the container also runs offline).

Build the image:

```bash
./build-docker.bash                 # tags as hayroll-eval:latest
```

Run the evaluation inside the container:

```bash
docker run --rm -it hayroll-eval ./run_evaluation.bash
```

The artifact lives at `/opt/hayroll-eval` inside the container. To keep the generated `.json` / `.tex` files on the host, mount a results directory:

```bash
docker run --rm -it -v "$PWD/hayroll-eval-results:/opt/hayroll-eval/hayroll-eval-results" hayroll-eval \
    bash -c './run_evaluation.bash && cp aggregated*.json benchmark_summary.json *.tex hayroll-eval-results/ && chmod -R a+rw hayroll-eval-results/'
```

## Output Files

### Generated Data Files
```
aggregated_statistics_crust.json        # CRUST macro statistics
aggregated_statistics_libmcs.json       # libmcs macro statistics
aggregated_statistics_zlib.json         # zlib macro statistics

aggregated_performance_crust.json       # CRUST pipeline performance
aggregated_performance_libmcs.json      # libmcs pipeline performance
aggregated_performance_zlib.json        # zlib pipeline performance
```

### Generated LaTeX Tables

Each `.tex` file corresponds to a table in the paper:

| File | Paper Table |
| --- | --- |
| `outcome_table_crust.tex`  | Table 4: CRUST-Bench translation outcomes |
| `outcome_table_libmcs.tex` | Table 5: LibmCS translation outcomes |
| `outcome_table_zlib.tex`   | Table 6: zlib translation outcomes |
| `failing_table.tex`        | Table 7: macro rejection reasons (all benchmarks) |
| `performance_table.tex`    | Table 8: end-to-end performance comparison (all benchmarks) |

All tables are generated automatically, including `failing_table.tex` (Table 7). No manual editing is involved.

## Verifying Correctness

The claim under evaluation is that Hayroll produces a Rust translation whose test suite passes on each benchmark. Check the console output at the end of `run_evaluation.bash`:

- **CRUST-Bench**: the analyzer prints `Tests Passed: 33/33`. A few programs have flaky tests. See *Expected Discrepancies* below.
- **libmcs** and **zlib**: the aggregated log should finish without an error-terminate.

## Expected Discrepancies from the Paper

Exact numbers may differ from the paper, but the high-level conclusions should hold. The usual sources of drift:

- **Tables 4–6 (outcomes)**: Counts depend on which system headers and macro definitions the host's C toolchain exposes, so per-category totals can shift slightly between machines and distros.
- **Table 7 (rejection reasons)**: Generated from the same underlying data as Tables 4–6, so it varies with them.
- **Table 8 (performance)**: Wall-clock numbers depend on CPU, memory pressure, and concurrency. Relative ordering and order-of-magnitude ratios are the stable signal, not the absolute seconds.

Individual CRUST-Bench programs that may occasionally fail for reasons unrelated to translation correctness:

- `libpsbt`: May report `misaligned pointer dereference`. `tx.c` uses the `__FILE__` macro to generate C-strings and manipulates those with raw pointers. Depending on which temporary folders Hayroll uses during transpilation, it may or may not trigger this issue.
- `clog`: Includes a performance test which may fail on less powerful machines.
- `fs_c`: Verifies that opening `/root/foo` for writing fails (i.e. the process lacks permission). When running as root (e.g. inside a Docker container), this write succeeds and the assertion fires. This is a pre-existing issue in the upstream test, not a Hayroll bug.

Some other test programs may fail due to transpilation or cargo build timeout, more often on less powerful machines. You can adjust `max_workers` in `benchmark_crust.py` to reduce the number of parallel processes and mitigate this.
