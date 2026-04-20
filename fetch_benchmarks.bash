#!/bin/bash
set -e

# Benchmark download and setup script.
# CRUST-Bench is unpacked under CBench/.
# Git benchmarks are cloned into the repository root and then overlaid with
# their benchmark-specific patch trees from *_patch/.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BENCHMARKS=(
    "crust|https://github.com/anirudhkhatry/CRUST-bench/raw/9d1aaeea1033814bbf4c1626cab198d1235f6f7f/datasets/CRUST_bench.zip|zip"
    "libmcs|https://gitlab.com/gtd-gmbh/libmcs|git|1.2.0"
    "zlib|https://github.com/madler/zlib|git|v1.3.1"
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
    if [ -d "$SCRIPT_DIR/CBench" ]; then
        echo "CRUST already present at $SCRIPT_DIR/CBench, skipping"
        return
    fi
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

# Overlay local benchmark patch files into the fetched source tree.
apply_patch_tree() {
    local name="$1"
    local dest="$2"
    local patch_dir="$SCRIPT_DIR/${name}_patch"

    if [ ! -d "$patch_dir" ]; then
        echo "No patch directory for $name at $patch_dir, skipping patch overlay"
        return
    fi

    echo "Applying local patch overlay from $patch_dir to $dest"
    cp -a "$patch_dir/." "$dest/"
}

# Download git repository at specific tag/branch into ./<name>
download_git_bench() {
    local name="$1"
    local url="$2"
    local branch="$3"
    local dest="$SCRIPT_DIR/$name"
    if [ ! -d "$dest" ]; then
        echo "Cloning $name from $url (ref: $branch)"
        git clone -q -b "$branch" "$url" "$dest"
    else
        echo "$name already present at $dest, skipping clone"
    fi
    apply_patch_tree "$name" "$dest"
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
