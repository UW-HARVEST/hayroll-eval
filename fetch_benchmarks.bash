#!/bin/bash
set -e

# Benchmark download and setup script
# Downloads multiple benchmarks and organizes them into separate directories

BENCHMARKS=(
    "crust|https://github.com/anirudhkhatry/CRUST-bench/raw/9d1aaeea1033814bbf4c1626cab198d1235f6f7f/datasets/CRUST_bench.zip|zip"
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
    # Delete existing zip file to avoid corruption from incomplete downloads
    rm -f CRUST_bench.zip
    echo "Fetching CRUST_bench.zip"
    wget -q "$url"
    echo "Unpacking CBench"
    unzip -q CRUST_bench.zip "CBench/*"
    # Remove embedded .git directories in CBench projects
    find CBench -type d -name ".git" -exec rm -rf {} + 2>/dev/null || true
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
}

main "$@"
