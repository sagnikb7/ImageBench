#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
ARCH_NAME="$(uname -m)"
TOOLS_DIR="$ROOT_DIR/Vendor/Tools"

if [[ ! -x "$TOOLS_DIR/$ARCH_NAME/cjpeg" || ! -x "$TOOLS_DIR/exiftool" ]]; then
    print "Fetching integration-test dependencies…"
    "$ROOT_DIR/Scripts/fetch-dependencies.sh" "$TOOLS_DIR"
fi

export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/imagebench-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/tmp}/imagebench-swiftpm-cache"

print "Checking source style…"
"$ROOT_DIR/Scripts/lint.sh"

"$ROOT_DIR/Scripts/test-package-preflight.sh"

print "Running debug tests…"
swift test --disable-sandbox --package-path "$ROOT_DIR"

print "Building and testing optimized code…"
swift test -c release --disable-sandbox --package-path "$ROOT_DIR"

print "Packaging and smoke-testing the offline app…"
"$ROOT_DIR/Scripts/package-app.sh"

print "All ImageBench verification passed."
