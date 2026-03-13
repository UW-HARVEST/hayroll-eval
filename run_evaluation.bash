#!/bin/bash
set -e

# Complete evaluation pipeline for all benchmarks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAYROLL_PATH="${HAYROLL_PATH:-$HOME/Hayroll/hayroll}"

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
        echo "Set HAYROLL_PATH environment variable or install Hayroll at ~/Hayroll/hayroll"
        exit 1
    fi

    log_success "All dependencies found"
}

# Download benchmarks if not already present
download_benchmarks() {
    log_section "Downloading benchmarks"

    if [ ! -d "$SCRIPT_DIR/CBench" ] && [ ! -f "$SCRIPT_DIR/CRUST_bench.zip" ]; then
        bash "$SCRIPT_DIR/fetch-benchmarks.bash"
    else
        log_success "Benchmarks already present"
    fi
}

# ============================================================================
# CRUST Evaluation
# ============================================================================

eval_crust() {
    log_section "CRUST Evaluation (33 projects)"

    cd "$SCRIPT_DIR"

    # NOTE: benchmark_crust.py internally uses metadata-filtered.json for CRUST projects.
    # That file includes the 33 CRUST projects that C2Rust successfully transpiled and passed tests.
    # We did not include the generation of metadata-filtered.json in this script because
    # C2Rust produces some non-terminating code that either wastes time or require manual intervention to filter out.
    # To manually run the full pipeline from scratch:
    #   export HAYROLL_PATH=/path/to/hayroll
    #   python3 generate_metadata_crust.py
    #   python3 benchmark_crust.py --hayroll $HAYROLL_PATH
    #   python3 filter_failing_metadata_crust.py

    # Step 1: Run full benchmark
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

    local LIBMCS_SRC="$SCRIPT_DIR/benchmarks/libmcs"
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
    LIBMCS_SRC="$LIBMCS_SRC" bash "$SCRIPT_DIR/libmcs/test_libmcs.bash" >> "$log_file" 2>&1 || true  # Continue even if tests fail

    # Step 6: Aggregate results
    log_section "Aggregating libmcs results"
    python3 "$SCRIPT_DIR/libmcs/aggregate_reports.py" --output "$SCRIPT_DIR/aggregated_statistics_libmcs.json" >> "$log_file" 2>&1
    cd "$SCRIPT_DIR"
    log_success "libmcs aggregation completed"
}

# ============================================================================
# zlib Evaluation
# ============================================================================

eval_zlib() {
    log_section "zlib Evaluation"

    local ZLIB_SRC="$SCRIPT_DIR/benchmarks/zlib"
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
    "$HAYROLL_PATH" compile_commands.json -w "$SCRIPT_DIR/zlib/whitelist.json" hayroll_out >> "$log_file" 2>&1
    log_success "Transpilation completed"

    # Step 4: Build Rust code
    log_section "Building Rust code for zlib"
    cd hayroll_out
    cargo build >> "../$log_file" 2>&1
    cd ..
    log_success "Rust build completed"

    # Step 5: Run tests
    log_section "Running zlib tests"
    ZLIB_SRC="$ZLIB_SRC" bash "$SCRIPT_DIR/zlib/test_zlib.bash" >> "$log_file" 2>&1 || true  # Continue even if tests fail

    # Step 6: Aggregate results
    log_section "Aggregating zlib results"
    python3 "$SCRIPT_DIR/zlib/aggregate_reports.py" --output "$SCRIPT_DIR/aggregated_statistics_zlib.json" >> "$log_file" 2>&1
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
    python3 generate_outcome_table.py aggregated_statistics_crust.json --output outcome_table.tex
    python3 generate_outcome_table.py aggregated_statistics_libmcs.json --output outcome_table_libmcs.tex
    python3 generate_outcome_table.py aggregated_statistics_zlib.json --output outcome_table_zlib.tex
    log_success "Outcome tables generated"

    # Generate performance table (combined)
    log_section "Generating performance table"
    python3 generate_performance_table.py \
        aggregated_performance_crust.json \
        aggregated_performance_libmcs.json \
        aggregated_performance_zlib.json \
        --output performance_table.tex
    log_success "Performance table generated"

    # Generate failing reasons table (combined)
    log_section "Generating failing reasons table"
    python3 generate_failing_table.py \
        aggregated_statistics_crust.json \
        aggregated_statistics_libmcs.json \
        aggregated_statistics_zlib.json \
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
    download_benchmarks

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
    echo "  - outcome_table.tex, outcome_table_libmcs.tex, outcome_table_zlib.tex"
    echo "  - performance_table.tex"
    echo "  - failing_table.tex"
}

# Run main function
main "$@"
