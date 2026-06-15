#!/usr/bin/env bash
# Shared test utilities for devcontainer features

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log functions
log_info() {
  echo -e "${GREEN}ℹ${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
  echo -e "${RED}✗${NC} $*" >&2
}

log_success() {
  echo -e "${GREEN}✓${NC} $*"
}

# Run feature test
run_feature_test() {
  local feature=$1
  local feature_path="src/${feature}"

  if [[ ! -d "$feature_path" ]]; then
    log_error "Feature not found: $feature_path"
    return 1
  fi

  if [[ ! -f "${feature_path}/test/test.sh" ]]; then
    log_error "Test script not found: ${feature_path}/test/test.sh"
    return 1
  fi

  log_info "Running tests for: $feature"

  # Run test script
  if bash "${feature_path}/test/test.sh"; then
    log_success "$feature tests passed"
    return 0
  else
    log_error "$feature tests failed"
    return 1
  fi
}

# Validate JSON schema
validate_json() {
  local file=$1

  if ! jq empty "$file" 2>/dev/null; then
    log_error "Invalid JSON: $file"
    return 1
  fi

  log_success "Valid JSON: $file"
  return 0
}

# Check if command exists
require_command() {
  local cmd=$1

  if ! command -v "$cmd" &>/dev/null; then
    log_error "Required command not found: $cmd"
    return 1
  fi
}
