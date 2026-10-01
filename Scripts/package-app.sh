#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
OUTPUT_DIR="${1:-$ROOT_DIR/dist}"
APP_DIR="$OUTPUT_DIR/ImageBench.app"
TOOLS_DIR="$ROOT_DIR/Vendor/Tools"
ARCH_NAME="$(uname -m)"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

if [[ ! -x "$TOOLS_DIR/$ARCH_NAME/cjpeg" || ! -x "$TOOLS_DIR/exiftool" || ! -d "$TOOLS_DIR/lib" || ! -f "$TOOLS_DIR/licenses/mozjpeg-LICENSE.md" || ! -f "$TOOLS_DIR/licenses/exiftool-README" ]]; then
    print "Packaged dependencies are absent; fetching and building them now."
    "$ROOT_DIR/Scripts/fetch-dependencies.sh" "$TOOLS_DIR"
fi

print "Building ImageBench (release)…"
CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/imagebench-clang-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/tmp}/imagebench-swiftpm-cache" \
swift build -c release --disable-sandbox --package-path "$ROOT_DIR"

BIN_DIR="$(swift build -c release --show-bin-path --disable-sandbox --package-path "$ROOT_DIR")"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources/bin/$ARCH_NAME" "$APP_DIR/Contents/Resources/Licenses"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$BIN_DIR/ImageBench" "$APP_DIR/Contents/MacOS/ImageBench"
xcrun actool \
    --compile "$APP_DIR/Contents/Resources" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$APP_DIR/Contents/Resources/AppIcon-partial.plist" \
    "$ROOT_DIR/Packaging/Assets.xcassets"
rm "$APP_DIR/Contents/Resources/AppIcon-partial.plist"

if [[ -d "$BIN_DIR/ImageBench_ImageBench.bundle" ]]; then
    cp -R "$BIN_DIR/ImageBench_ImageBench.bundle" "$APP_DIR/Contents/Resources/"
fi
cp "$TOOLS_DIR/$ARCH_NAME/cjpeg" "$APP_DIR/Contents/Resources/bin/$ARCH_NAME/cjpeg"
cp "$TOOLS_DIR/exiftool" "$APP_DIR/Contents/Resources/bin/exiftool"
cp -R "$TOOLS_DIR/lib" "$APP_DIR/Contents/Resources/bin/lib"
cp "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$APP_DIR/Contents/Resources/ThirdPartyNotices.md"
cp "$ROOT_DIR/LICENSE" "$APP_DIR/Contents/Resources/LICENSE"
cp "$ROOT_DIR/Sources/ImageBench/Resources/Licenses/Fraunces-OFL.txt" "$APP_DIR/Contents/Resources/Licenses/Fraunces-OFL.txt"
cp "$ROOT_DIR/Sources/ImageBench/Resources/Licenses/Figtree-OFL.txt" "$APP_DIR/Contents/Resources/Licenses/Figtree-OFL.txt"
if [[ -d "$TOOLS_DIR/licenses" ]]; then
    cp -R "$TOOLS_DIR/licenses/." "$APP_DIR/Contents/Resources/Licenses/"
fi
chmod 755 "$APP_DIR/Contents/MacOS/ImageBench" "$APP_DIR/Contents/Resources/bin/$ARCH_NAME/cjpeg" "$APP_DIR/Contents/Resources/bin/exiftool"

print "Signing with identity: $SIGNING_IDENTITY"
codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"
print "Created $APP_DIR"
