#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
WORK_DIR="$(mktemp -d /tmp/imagebench-preflight.XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "$WORK_DIR/output/ImageBench.app"
print 'previous app' > "$WORK_DIR/output/ImageBench.app/sentinel"

# An invalid developer directory must fail before modifying an existing output.
if DEVELOPER_DIR="$WORK_DIR/missing-xcode" "$ROOT_DIR/Scripts/package-app.sh" "$WORK_DIR/output" > "$WORK_DIR/log" 2>&1; then
    print -u2 "Packaging unexpectedly accepted an invalid developer directory"
    exit 1
fi
[[ "$(cat "$WORK_DIR/output/ImageBench.app/sentinel")" == 'previous app' ]]
grep -q 'Full Xcode is required' "$WORK_DIR/log"
[[ ! -e "$WORK_DIR/output/ImageBench.app/Contents" ]]
print 'Packaging preflight regression passed: actionable error and previous app preserved.'
