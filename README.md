# Hayroll Evaluation Pipeline

This guide explains how to run the complete evaluation pipeline for all three benchmarks (CRUST-Bench, libmcs, zlib) and generate the LaTeX tables in the paper.

## Files

### Main Scripts
- **`setup.bash`**: One-stop setup: builds Hayroll from the submodule and downloads all benchmarks
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
./setup.bash                               # fetch, build Hayroll and download benchmarks
./run_evaluation.bash                      # run full evaluation
```

`setup.bash` will:
1. Update git submodules (fetches Hayroll code into `Hayroll/`)
2. Build Hayroll from the `Hayroll/` submodule
3. Download benchmarks into `./CBench`, `./libmcs`, and `./zlib`
4. Overlay local patch files from `libmcs_patch/` and `zlib_patch/` onto the fetched git repositories

`run_evaluation.bash` will:
1. Check all dependencies (bear, make, gcc, cargo, python3, Hayroll)
2. Run all tests for CRUST-Bench, libmcs, and zlib
3. Aggregate results and generate LaTeX tables

It should take fewer than 25 minutes to run everything. Reference: Intel(R) Core(TM) i7-1370P CPU @ 1.90GHz × 14, 64GB RAM, on a poorly radiated machine.

## Docker

The image is self-contained. You only need to run:

```bash
./run_evaluation.bash
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
```
outcome_table_crust.tex                 # CRUST translation outcomes
outcome_table_libmcs.tex                # libmcs translation outcomes
outcome_table_zlib.tex                  # zlib translation outcomes

performance_table.tex                   # Combined performance comparison
failing_table.tex                       # Combined macro rejection reasons
```

## Additional Notes

Some test programs from CRUST-Bench may occasionally fail due to non-deterministic factors.

`libpsbt`: May report "misaligned pointer dereference". `tx.c` uses the `__FILE__` macro to generate C-strings and manipulates those with raw pointers. According to which temporary folders that Hayroll uses during transpilation, it may or may not trigger this issue.

`clog`: It includes a performance test which may fail on less powerful machines.

`fs_c`: It verifies that opening `/root/foo` for writing fails (i.e. the process lacks permission). When running as root (e.g. inside a Docker container), this write succeeds and the assertion fires. This is a pre-existing issue in the upstream test, not a Hayroll bug.

Some other test programs may fail due to transpilation or cargo build timeout. This also happens more often on less powerful machines. You can adjust `max_workers` in the `benchmark_crust.py` script to reduce the number of parallel processes and mitigate this issue.
