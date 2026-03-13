# Hayroll Tests

Automated test runner for validating C to Rust transpilation using the C2Rust toolchain.
It builds, transpiles, and tests C programs from the CRUST benchmark, summarizing results in a structured JSON file.

The current results of the benchmark can be viewed at [`test_results.json`](test_results.json).

`metadata-filtered.json` contains metadata about each program in the CRUST benchmark, and is used to run the transpilation and tests.

## Prerequisites

Requires installing [Hayroll](https://github.com/UW-HARVEST/Hayroll) and its dependencies. Please refer to the Hayroll repository for installation instructions. To make sure you are testing the latest Hayroll and its latest dependencies, please clone the main branch of the Hayroll repository, and when running `prerequisites.bash`, add `--latest`. You do not need to lean how to use Hayroll for this benchmark; the scripts will handle everything.

Requires `CBench` directory from the [CRUST benchmark]. To copy:
```sh
./fetch-CBench.bash
```

Other dependencies include: `python3`, `bear`, `make`, `gcc`, `cargo`, `c2rust`.

## Usage

To run the complete evaluation pipeline for all three benchmarks (CRUST, libmcs, zlib):

```sh
./run_evaluation.bash
```

### CRUST-specific scripts (for manual runs)

To generate CRUST metadata used to run tests:

```sh
python3 generate_metadata_crust.py
```

To run full CRUST benchmark (generates `benchmark_summary.json`):

```sh
python3 benchmark_crust.py --hayroll $HAYROLL_PATH
```

To filter out failed CRUST projects:

```sh
python3 filter_failing_metadata_crust.py
```

To view CRUST pass rate:

```sh
python3 analyze_crust.py
```

To view effectiveness and performance results (generates `aggregated_statistics_*.json` and `aggregated_performance_*.json`):

```sh
python aggregate_reports_crust.py --search-root CBench
```

To generate LaTeX tables:

```sh
python generate_outcome_table.py aggregated_statistics_crust.json
python generate_performance_table.py aggregated_performance_*.json
python generate_failing_table.py aggregated_statistics_*.json
```

## Notes

Currently excluding `skp` program because it always seems to hang.
