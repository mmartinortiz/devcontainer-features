#!/usr/bin/env bash
set -euo pipefail

# Local testing script - builds container and runs feature tests

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DOCKERFILE="${REPO_ROOT}/test/Dockerfile.test"
CONTAINER_NAME="devcontainer-features-test-$$"
CONTAINER_IMAGE="devcontainer-features:test"

cleanup() {
  echo ""
  echo "Cleaning up..."
  docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}

trap cleanup EXIT

echo "=== Building test container ==="
docker build -t "$CONTAINER_IMAGE" -f "$DOCKERFILE" "$REPO_ROOT"

echo ""
echo "=== Running feature installation and tests ==="
docker run \
  --name "$CONTAINER_NAME" \
  --rm \
  "$CONTAINER_IMAGE" \
  bash -c "
    set -euo pipefail

    echo '=== Running feature install.sh ==='
    bash src/neovim-pack/install.sh

    echo ''
    echo '=== Running feature tests ==='
    bash src/neovim-pack/test/test.sh

    echo ''
    echo '✓ All tests passed'
  "

echo ""
echo "=== Test run completed successfully ==="
