#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
DESTINATION="${1:-$ROOT_DIR/Vendor/Tools}"
WORK_DIR="$(mktemp -d /tmp/imagebench-deps.XXXXXX)"
MOZJPEG_VERSION="${MOZJPEG_VERSION:-4.1.5}"
EXIFTOOL_VERSION="${EXIFTOOL_VERSION:-13.25}"
MOZJPEG_SHA256="9fcbb7171f6ac383f5b391175d6fb3acde5e64c4c4727274eade84ed0998fcc1"
EXIFTOOL_SHA256="90ff1b1fa214215f30fa547a8f0d53e7355d995426e3102ef6c6020dd3efbb04"
ARCH_NAME="$(uname -m)"
export PATH="/opt/homebrew/opt/cmake/bin:/usr/local/opt/cmake/bin:$PATH"

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

for tool in awk curl cmake make perl shasum; do
    if ! command -v "$tool" >/dev/null; then
        print -u2 "Required build tool is missing: $tool"
        exit 1
    fi
done

verify_checksum() {
    local archive="$1"
    local expected="$2"
    local actual
    actual="$(shasum -a 256 "$archive" | awk '{print $1}')"
    if [[ "$actual" != "$expected" ]]; then
        print -u2 "Checksum verification failed for ${archive:t}."
        print -u2 "Expected: $expected"
        print -u2 "Actual:   $actual"
        exit 1
    fi
}

mkdir -p "$DESTINATION/$ARCH_NAME"
mkdir -p "$DESTINATION/licenses"

print "Downloading mozjpeg $MOZJPEG_VERSION source…"
curl --fail --location --retry 3 \
    "https://github.com/mozilla/mozjpeg/archive/refs/tags/v${MOZJPEG_VERSION}.tar.gz" \
    --output "$WORK_DIR/mozjpeg.tar.gz"
verify_checksum "$WORK_DIR/mozjpeg.tar.gz" "$MOZJPEG_SHA256"
tar -xzf "$WORK_DIR/mozjpeg.tar.gz" -C "$WORK_DIR"
cmake -S "$WORK_DIR/mozjpeg-$MOZJPEG_VERSION" -B "$WORK_DIR/mozjpeg-build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DENABLE_SHARED=OFF \
    -DWITH_TURBOJPEG=OFF \
    -DPNG_SUPPORTED=OFF
cmake --build "$WORK_DIR/mozjpeg-build" --target cjpeg-static --parallel
cp "$WORK_DIR/mozjpeg-build/cjpeg-static" "$DESTINATION/$ARCH_NAME/cjpeg"
chmod 755 "$DESTINATION/$ARCH_NAME/cjpeg"
cp "$WORK_DIR/mozjpeg-$MOZJPEG_VERSION/LICENSE.md" "$DESTINATION/licenses/mozjpeg-LICENSE.md"

print "Downloading ExifTool $EXIFTOOL_VERSION…"
curl --fail --location --retry 3 \
    "https://github.com/exiftool/exiftool/archive/refs/tags/${EXIFTOOL_VERSION}.tar.gz" \
    --output "$WORK_DIR/exiftool.tar.gz"
verify_checksum "$WORK_DIR/exiftool.tar.gz" "$EXIFTOOL_SHA256"
tar -xzf "$WORK_DIR/exiftool.tar.gz" -C "$WORK_DIR"
cp "$WORK_DIR/exiftool-$EXIFTOOL_VERSION/exiftool" "$DESTINATION/exiftool"
rm -rf "$DESTINATION/lib"
cp -R "$WORK_DIR/exiftool-$EXIFTOOL_VERSION/lib" "$DESTINATION/lib"
chmod 755 "$DESTINATION/exiftool"
cp "$WORK_DIR/exiftool-$EXIFTOOL_VERSION/README" "$DESTINATION/licenses/exiftool-README"

print "Offline dependencies are ready in $DESTINATION"
