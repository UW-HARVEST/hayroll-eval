#!/bin/bash
set -e

# Benchmark download and setup script
# Downloads multiple benchmarks and organizes them into separate directories

BENCHMARKS=(
    "crust|https://raw.github.com/anirudhkhatry/CRUST-bench/main/datasets/CRUST_bench.zip|zip"
    "libmcs|https://github.com/UW-HARVEST/LibmCS|git|hayroll-eval"
    "zlib|https://github.com/UW-HARVEST/zlib|git|hayroll-eval"
)

# Parse benchmark specification
# Format: name|url|type[|branch]
parse_benchmark() {
    local spec="$1"
    IFS='|' read -r name url type branch <<< "$spec"
    echo "$name" "$url" "$type" "$branch"
}

# Download and setup CRUST benchmark
download_crust() {
    local url="$1"
    echo "Fetching CRUST_bench.zip"
    wget -q "$url"
    echo "Unpacking CBench"
    unzip -q CRUST_bench.zip "CBench/*"
    rm CRUST_bench.zip
}

# Download git repository at specific branch
download_git_bench() {
    local name="$1"
    local url="$2"
    local branch="$3"
    echo "Cloning $name from $url (branch: $branch)"
    git clone -q -b "$branch" "$url" "$name"
}

# Main download logic
main() {
    echo "Starting benchmark downloads..."

    for bench_spec in "${BENCHMARKS[@]}"; do
        read -r name url type branch <<< "$(parse_benchmark "$bench_spec")"

        case "$type" in
            zip)
                download_crust "$url"
                ;;
            git)
                download_git_bench "$name" "$url" "$branch"
                ;;
            *)
                echo "Error: Unknown benchmark type '$type'"
                exit 1
                ;;
        esac
    done

    echo "All benchmarks downloaded successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Run Hayroll evaluation on each benchmark"
    echo "  2. Use aggregate_reports.py to process results"
    echo ""
    echo "Directory structure:"
    echo "  CBench/          - CRUST benchmark projects"
    echo "  libmcs/          - LibmCS library code"
    echo "  zlib/            - zlib library code"
}

main "$@"
