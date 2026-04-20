#!/usr/bin/env bash
# Build the Hayroll evaluation Docker image.
#
# Usage:
#   ./build-docker.bash [--no-cache] [TAG]
#
# Examples:
#   ./build-docker.bash                       # tags as hayroll-eval:latest
#   ./build-docker.bash --no-cache            # force full rebuild
#   ./build-docker.bash hayroll-eval:v1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NO_CACHE=""
TAG="hayroll-eval"

for arg in "$@"; do
    case "$arg" in
        --no-cache) NO_CACHE="--no-cache" ;;
        *)          TAG="$arg" ;;
    esac
done

docker build --network=host $NO_CACHE -t "${TAG}" "$SCRIPT_DIR"
