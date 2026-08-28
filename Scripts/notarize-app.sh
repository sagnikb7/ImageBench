#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
APP_PATH="${1:-$ROOT_DIR/dist/ImageBench.app}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
ARCHIVE_PATH="${APP_PATH:h}/ImageBench-notarization.zip"

if [[ -z "$NOTARY_PROFILE" ]]; then
    print -u2 "Set NOTARY_PROFILE to an xcrun notarytool keychain profile."
    exit 2
fi
if [[ ! -d "$APP_PATH" ]]; then
    print -u2 "App bundle not found: $APP_PATH"
    exit 2
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ARCHIVE_PATH"
xcrun notarytool submit "$ARCHIVE_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=2 "$APP_PATH"
print "Notarization complete: $APP_PATH"
