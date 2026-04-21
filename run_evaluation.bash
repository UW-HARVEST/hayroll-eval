#!/bin/bash
set -e

# Complete evaluation pipeline for all benchmarks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAYROLL_PATH="${HAYROLL_PATH:-$SCRIPT_DIR/Hayroll/hayroll}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_section() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verify dependencies
check_dependencies() {
    log_section "Checking dependencies"

    local deps=("bear" "make" "gcc" "cargo" "python3")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Missing dependency: $dep"
            exit 1
        fi
    done

    if [ ! -f "$HAYROLL_PATH" ]; then
        log_error "Hayroll not found at: $HAYROLL_PATH"
        echo "Set HAYROLL_PATH environment variable or run ./setup.bash to build Hayroll"
        exit 1
    fi

    log_success "All dependencies found"
}

# ============================================================================
# CRUST Evaluation
# ============================================================================

eval_crust() {
    log_section "CRUST Evaluation (33 projects)"

    cd "$SCRIPT_DIR"

    # metadata-filtered.json is pre-generated and included in this repository.
    # It contains the subset of CRUST projects on which C2Rust (the baseline tool)
    # successfully transpiled, built, and passed all tests. Restricting Hayroll's
    # evaluation to this subset ensures a fair comparison: we only measure projects
    # that the baseline can also handle.
    #
    # If you need to regenerate metadata-filtered.json from scratch (e.g. after
    # updating the benchmark set), the process is:
    #   1. python3 generate_metadata_crust.py          # discover all test files -> metadata.json
    #   2. python3 benchmark_crust.py --c2rust         # run C2Rust on all projects
    #   3. python3 filter_failing_metadata_crust.py    # keep only C2Rust-passing projects
    #
    # Note: C2Rust occasionally produces non-terminating translated code. Step 2 may
    # require manually killing stuck processes before proceeding to step 3.

    # Step 1: Run full benchmark on filtered (C2Rust-passing) projects
    log_section "Running full CRUST evaluation"
    python3 benchmark_crust.py --hayroll "$HAYROLL_PATH"
    log_success "Benchmark completed"

    # Step 2: Analyze results
    log_section "Analyzing CRUST results"
    python3 analyze_crust.py

    # Step 3: Aggregate statistics and performance
    log_section "Aggregating CRUST results"
    python3 aggregate_reports_crust.py --search-root CBench --output aggregated_statistics_crust.json
    log_success "CRUST aggregation completed"
}

# ============================================================================
# libmcs Evaluation
# ============================================================================

eval_libmcs() {
    log_section "libmcs Evaluation"

    local LIBMCS_SRC="$SCRIPT_DIR/libmcs"
    cd "$LIBMCS_SRC"

    local log_file="libmcs_eval.log"

    # Step 1: Configure with specific flags
    log_section "Configuring libmcs"
    ./configure \
        --cross-compile="" \
        --compilation-flags="" \
        --disable-denormal-handling \
        --disable-long-double-procedures \
        --disable-complex-procedures \
        --little-endian > "$log_file" 2>&1
    log_success "libmcs configured (output: $log_file)"

    # Step 2: Generate compile_commands.json
    log_section "Generating compile_commands.json for libmcs"
    make clean >> "$log_file" 2>&1
    bear -- make >> "$log_file" 2>&1
    log_success "compile_commands.json generated"

    # Step 3: Run Hayroll transpilation
    log_section "Running Hayroll transpilation for libmcs"
    rm -rf hayroll_out
    "$HAYROLL_PATH" compile_commands.json hayroll_out >> "$log_file" 2>&1
    log_success "Transpilation completed"

    # Step 4: Build Rust code
    log_section "Building Rust code for libmcs"
    cd hayroll_out
    cargo build >> "../$log_file" 2>&1
    cd ..
    log_success "Rust build completed"

    # Step 5: Run tests
    log_section "Running libmcs tests"
    bash "$LIBMCS_SRC/test_libmcs.bash" >> "$log_file" 2>&1 || log_error "libmcs tests failed (see $log_file)"

    # Step 6: Aggregate results
    log_section "Aggregating libmcs results"
    python3 "$SCRIPT_DIR/aggregate_reports_libmcs.py" --search-root "$LIBMCS_SRC" --output "$SCRIPT_DIR/aggregated_statistics_libmcs.json" >> "$log_file" 2>&1
    cd "$SCRIPT_DIR"
    log_success "libmcs aggregation completed"
}

# ============================================================================
# zlib Evaluation
# ============================================================================

eval_zlib() {
    log_section "zlib Evaluation"

    local ZLIB_SRC="$SCRIPT_DIR/zlib"
    cd "$ZLIB_SRC"

    local log_file="zlib_eval.log"

    # Step 1: Configure
    log_section "Configuring zlib"
    ./configure > "$log_file" 2>&1
    log_success "zlib configured"

    # Step 2: Generate compile_commands.json
    log_section "Generating compile_commands.json for zlib"
    make clean >> "$log_file" 2>&1
    bear -- make >> "$log_file" 2>&1
    log_success "compile_commands.json generated"

    # Step 3: Run Hayroll transpilation
    log_section "Running Hayroll transpilation for zlib"
    rm -rf hayroll_out
    "$HAYROLL_PATH" compile_commands.json -w "$ZLIB_SRC/whitelist.json" hayroll_out >> "$log_file" 2>&1
    log_success "Transpilation completed"

    # Step 4: Build Rust code
    log_section "Building Rust code for zlib"
    cd hayroll_out
    cargo build >> "../$log_file" 2>&1
    cd ..
    log_success "Rust build completed"

    # Step 5: Run tests
    log_section "Running zlib tests"
    bash "$ZLIB_SRC/test_zlib.bash" >> "$log_file" 2>&1 || log_error "zlib tests failed (see $log_file)"

    # Step 6: Aggregate results
    log_section "Aggregating zlib results"
    python3 "$SCRIPT_DIR/aggregate_reports_zlib.py" --search-root "$ZLIB_SRC" --output "$SCRIPT_DIR/aggregated_statistics_zlib.json" >> "$log_file" 2>&1
    cd "$SCRIPT_DIR"
    log_success "zlib aggregation completed"
}

# ============================================================================
# Table Generation
# ============================================================================

generate_tables() {
    log_section "Generating LaTeX tables"

    cd "$SCRIPT_DIR"

    # Generate outcome tables for each benchmark
    log_section "Generating outcome tables"
    python3 generate_outcome_table.py aggregated_statistics_crust.json --name CRUST --output outcome_table_crust.tex
    python3 generate_outcome_table.py aggregated_statistics_libmcs.json --name libmcs --output outcome_table_libmcs.tex
    python3 generate_outcome_table.py aggregated_statistics_zlib.json --name zlib --output outcome_table_zlib.tex
    log_success "Outcome tables generated"

    # Generate performance table (combined)
    log_section "Generating performance table"
    python3 generate_performance_table.py \
        aggregated_performance_crust.json \
        aggregated_performance_libmcs.json \
        aggregated_performance_zlib.json \
        --column-names CRUST libmcs zlib \
        --output performance_table.tex
    log_success "Performance table generated"

    # Generate failing reasons table (combined)
    log_section "Generating failing reasons table"
    python3 generate_failing_table.py \
        aggregated_statistics_crust.json \
        aggregated_statistics_libmcs.json \
        aggregated_statistics_zlib.json \
        --column-names CRUST libmcs zlib \
        --output failing_table.tex
    log_success "Failing reasons table generated"
}

# ============================================================================
# Main orchestration
# ============================================================================

main() {
    log_section "Complete Evaluation Pipeline"
    echo "All benchmarks: CRUST, libmcs, zlib"
    echo ""

    check_dependencies

    # Run evaluation for each benchmark
    eval_crust
    eval_libmcs
    eval_zlib

    # Generate all tables
    generate_tables

    log_section "Pipeline Complete"
    echo -e "${GREEN}All evaluations and table generation completed!${NC}"
    echo ""
    echo "Generated files:"
    echo "  - aggregated_statistics_crust.json, aggregated_statistics_libmcs.json, aggregated_statistics_zlib.json"
    echo "  - aggregated_performance_crust.json, aggregated_performance_libmcs.json, aggregated_performance_zlib.json"
    echo "  - outcome_table_crust.tex, outcome_table_libmcs.tex, outcome_table_zlib.tex"
    echo "  - performance_table.tex"
    echo "  - failing_table.tex"
}

# Run main function
main "$@"
