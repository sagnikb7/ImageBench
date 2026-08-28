#!/bin/zsh
set -euo pipefail

export IMAGEBENCH_RUN_BENCHMARKS=1
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/imagebench-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/tmp}/imagebench-swiftpm-cache"

swift test --disable-sandbox --filter CompressorScaleTests
