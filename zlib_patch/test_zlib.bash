#!/bin/bash
# Test zlib translated Rust code using standard test utilities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ZLIB_SRC: path to fetched zlib source tree (defaults to same dir for standalone use)
ZLIB_SRC="${ZLIB_SRC:-$SCRIPT_DIR}"
cd "$ZLIB_SRC"

echo "Building and testing zlib..."

# Verify hayroll_out exists
if [ ! -d "hayroll_out" ]; then
    echo "Error: hayroll_out directory not found"
    exit 1
fi

# Verify cargo build succeeded
if [ ! -d "hayroll_out/target/debug" ]; then
    echo "Error: Rust build output not found at hayroll_out/target/debug"
    exit 1
fi

# Compile test programs against the translated Hayroll library
echo "Compiling test programs..."

# Compile minigzip test
gcc -o minigzip_test test/minigzip.c \
    -I. \
    -L hayroll_out/target/debug \
    -lhayroll_out \
    -ldl -lpthread -lm

# Compile example test
gcc -o example_test test/example.c \
    -I. \
    -L hayroll_out/target/debug \
    -lhayroll_out \
    -ldl -lpthread -lm

echo ""
echo "Running zlib minigzip test..."
if echo "hello world" | LD_LIBRARY_PATH=hayroll_out/target/debug:$LD_LIBRARY_PATH ./minigzip_test | LD_LIBRARY_PATH=hayroll_out/target/debug:$LD_LIBRARY_PATH ./minigzip_test -d; then
    echo "✓ minigzip test PASSED"
else
    echo "✗ minigzip test FAILED"
fi

echo ""
echo "Running zlib example test..."
if LD_LIBRARY_PATH=hayroll_out/target/debug:$LD_LIBRARY_PATH ./example_test; then
    echo "✓ example test PASSED"
else
    echo "✗ example test FAILED"
fi

# Cleanup
rm -f minigzip_test example_test test_file.gz

echo ""
echo "zlib testing completed"
