#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PREFIX_DIR=/tmp/subconverter-static-prefix
BUILD_DIR=/tmp/subconverter-alpine-static-build-current
OUTPUT_DIR="$REPO_DIR/build"
OUTPUT_BIN="$OUTPUT_DIR/subconverter-linux-musl-static"

if [ ! -f "$PREFIX_DIR/lib/libyaml-cpp.a" ] || [ ! -f "$PREFIX_DIR/lib/quickjs/libquickjs.a" ] || [ ! -f "$PREFIX_DIR/lib/liblibcron.a" ]; then
    echo "Missing cached static dependencies under $PREFIX_DIR" >&2
    echo "Expected: libyaml-cpp.a, libquickjs.a, liblibcron.a" >&2
    exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

cd "$BUILD_DIR"
cmake "$REPO_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$PREFIX_DIR" \
    -DCMAKE_FIND_LIBRARY_SUFFIXES=.a \
    -DCURL_LIBRARY=/usr/lib/libcurl.a \
    -DCURL_INCLUDE_DIR=/usr/include \
    -DPCRE2_LIBRARY=/usr/lib/libpcre2-8.a \
    -DYAML_CPP_LIBRARY="$PREFIX_DIR/lib/libyaml-cpp.a" \
    -DCMAKE_EXE_LINKER_FLAGS="-static -Wl,--whole-archive -lpthread -Wl,--no-whole-archive"

cmake --build . -j4 || true

LINK_CMD="$(cat CMakeFiles/subconverter.dir/link.txt) $(pkg-config --libs --static libcurl)"
eval "$LINK_CMD"

file subconverter
ldd subconverter || true

cp subconverter "$OUTPUT_BIN"
echo "Static binary copied to: $OUTPUT_BIN"
