#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_BIN="${TMPDIR:-/tmp}/api_environment_logic_regressions"
MODULE_CACHE_DIR="${TMPDIR:-/tmp}/api_environment_logic_module_cache"

mkdir -p "$MODULE_CACHE_DIR"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  "$ROOT_DIR/Core/Models/BookingModels.swift" \
  "$ROOT_DIR/APIEnvironment/AppLogic.swift" \
  "$ROOT_DIR/Scripts/logic_regression.swift" \
  -o "$OUTPUT_BIN"

"$OUTPUT_BIN"
