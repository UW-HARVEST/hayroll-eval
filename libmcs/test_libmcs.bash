#!/bin/bash
# Test libmcs translated Rust code using the standard test suite

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LIBMCS_SRC: path to fetched libmcs source tree (defaults to same dir for standalone use)
LIBMCS_SRC="${LIBMCS_SRC:-$SCRIPT_DIR}"

# Link our test suite into the source tree so Makefile relative paths (../libm/include,
# ../hayroll_out) resolve correctly against the source tree root.
ln -sfn "$SCRIPT_DIR/test" "$LIBMCS_SRC/test-hayroll-suite"
cd "$LIBMCS_SRC/test-hayroll-suite"

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
