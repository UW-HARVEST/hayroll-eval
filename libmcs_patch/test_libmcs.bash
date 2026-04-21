#!/bin/bash
# Test libmcs translated Rust code using the overlaid standard test suite.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBMCS_SRC="$SCRIPT_DIR"
cd "$LIBMCS_SRC/test"

echo "Building and running libmcs tests..."

# Verify hayroll_out exists
if [ ! -d "$LIBMCS_SRC/hayroll_out" ]; then
    echo "Error: $LIBMCS_SRC/hayroll_out directory not found"
    exit 1
fi

# Verify cargo build succeeded
if [ ! -d "$LIBMCS_SRC/hayroll_out/target/debug" ]; then
    echo "Error: Rust build output not found at $LIBMCS_SRC/hayroll_out/target/debug"
    exit 1
fi

# Run the standard test suite (builds test-double and test-float, then runs them)
make clean
make
echo ""
echo "Running test-float..."
./test-float
echo ""
echo "Running test-double..."
./test-double

echo ""
echo "libmcs testing completed successfully"
