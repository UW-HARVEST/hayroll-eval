# Hayroll Evaluation Pipeline

This guide explains how to run the complete evaluation pipeline for all three benchmarks (CRUST, libmcs, zlib) and generate the final LaTeX tables for your paper.

## Files

### Main Scripts
- **`run_evaluation.bash`** - Master orchestration script (runs everything)
- **`fetch_benchmarks.bash`** - Downloads all benchmark sources (CRUST, libmcs, zlib)

### Benchmark-Specific Scripts
- **`libmcs/test_libmcs.bash`** - Test runner for libmcs
- **`zlib/test_zlib.bash`** - Test runner for zlib

### Existing Evaluation Scripts

#### CRUST-specific scripts
- **`benchmark_crust.py`** - CRUST full evaluation (handles all 4 dimensions)
- **`generate_metadata_crust.py`** - Generates metadata for CRUST projects
- **`filter_failing_metadata_crust.py`** - Filters out failed CRUST projects
- **`analyze_crust.py`** - Analyzes CRUST pass rate

#### Aggregate scripts
- **`aggregate_reports_crust.py`** - Aggregates CRUST statistics and performance data
- **`libmcs/aggregate_reports.py`** - Aggregates libmcs statistics and performance data
- **`zlib/aggregate_reports.py`** - Aggregates zlib statistics and performance data
- **`generate_outcome_table.py`** - Generates translation outcome tables
- **`generate_performance_table.py`** - Generates performance comparison table
- **`generate_failing_table.py`** - Generates macro rejection reasons table

## Quick Start

```bash
./run_evaluation.bash
```

This will:
1. Check all dependencies (bear, make, gcc, cargo, python3, Hayroll)
2. Download benchmarks (if not already present)
3. **CRUST**: Full evaluation (metadata -> benchmark -> filter -> aggregate)
4. **libmcs**: Configure -> compile -> transpile -> build -> test -> aggregate
5. **zlib**: Configure -> compile -> transpile -> build -> test -> aggregate
6. Generate all LaTeX tables

It should take about 25 minutes to run everything.

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
