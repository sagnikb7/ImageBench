#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
APP_DIR="${1:-$ROOT_DIR/dist/ImageBench.app}"
ARCH_NAME="$(uname -m)"
CONTENTS="$APP_DIR/Contents"
CJPEG="$CONTENTS/Resources/bin/$ARCH_NAME/cjpeg"
EXIFTOOL="$CONTENTS/Resources/bin/exiftool"
WORK_DIR="$(mktemp -d /tmp/imagebench-smoke.XXXXXX)"

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

for required in "$CONTENTS/Info.plist" "$CONTENTS/MacOS/ImageBench" "$CJPEG" "$EXIFTOOL" "$CONTENTS/Resources/AppIcon.icns" "$CONTENTS/Resources/Assets.car" "$CONTENTS/Resources/LICENSE" "$CONTENTS/Resources/ThirdPartyNotices.md" "$CONTENTS/Resources/Licenses/mozjpeg-LICENSE.md" "$CONTENTS/Resources/Licenses/exiftool-README" "$CONTENTS/Resources/Licenses/ArchivoNarrow-OFL.txt" "$CONTENTS/Resources/ImageBench_ImageBench.bundle/ArchivoNarrow[wght].ttf"; do
    [[ -e "$required" ]] || { print -u2 "Missing bundle component: $required"; exit 1; }
done

[[ -x "$CONTENTS/MacOS/ImageBench" ]] || { print -u2 "App executable is not executable"; exit 1; }
[[ -x "$CJPEG" ]] || { print -u2 "Bundled cjpeg is not executable"; exit 1; }
[[ -x "$EXIFTOOL" ]] || { print -u2 "Bundled ExifTool is not executable"; exit 1; }
[[ -d "$CONTENTS/Resources/bin/lib/Image" ]] || { print -u2 "ExifTool Perl modules are missing"; exit 1; }

[[ "$(plutil -extract CFBundleIdentifier raw "$CONTENTS/Info.plist")" == "com.imagebench.imagetools" ]]
[[ "$(plutil -extract CFBundleExecutable raw "$CONTENTS/Info.plist")" == "ImageBench" ]]
[[ "$(plutil -extract CFBundleIconFile raw "$CONTENTS/Info.plist")" == "AppIcon" ]]
codesign --verify --deep --strict "$APP_DIR"

if otool -L "$CJPEG" | grep -qE '/opt/homebrew|/usr/local'; then
    print -u2 "Bundled cjpeg has a non-portable Homebrew linkage"
    exit 1
fi
"$CJPEG" -version 2>&1 | grep -qi mozjpeg
"$EXIFTOOL" -ver | grep -Eq '^[0-9]+\.[0-9]+'

PPM="$WORK_DIR/smoke.ppm"
JPEG="$WORK_DIR/smoke.jpg"
printf 'P3\n2 2\n255\n255 0 0  0 255 0\n0 0 255  255 255 255\n' > "$PPM"
"$CJPEG" -quality 82 -progressive -optimize -quant-table 3 -sample 2x2 -outfile "$JPEG" "$PPM"
[[ -s "$JPEG" ]]
[[ "$(sips -g pixelWidth "$JPEG" | awk '/pixelWidth/ {print $2}')" == "2" ]]
[[ "$(sips -g pixelHeight "$JPEG" | awk '/pixelHeight/ {print $2}')" == "2" ]]

print "ImageBench bundle smoke test passed: $APP_DIR"
