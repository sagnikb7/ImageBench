#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
FORMATTER="$(xcrun --find swift-format)"

"$FORMATTER" lint \
    --strict \
    --parallel \
    --recursive \
    --configuration "$ROOT_DIR/.swift-format" \
    "$ROOT_DIR/Package.swift" \
    "$ROOT_DIR/Scripts/generate-app-icon.swift" \
    "$ROOT_DIR/Sources" \
    "$ROOT_DIR/Tests"

print "Swift formatting and lint checks passed."
