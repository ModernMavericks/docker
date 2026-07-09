#!/bin/sh
# Build macports-legacy-support -> $OUT/lib/libMacportsLegacySupport.a.
# Called by the legacy_support ExternalProject: all inputs absolute/explicit,
# no host detection, no clone, no relative paths. Args:
#   $1 SRC    absolute cloned source dir (BUILD_IN_SOURCE)
#   $2 OUT    absolute install prefix
#   $3 CC     C compiler
#   $4 ARCHS  Makefile ARCHS ("" on box; "x86_64" on ci)
#   $5 CFLAGS extra CFLAGS ("" on box; "-isysroot ... -mmacosx-version-min=10.9" on ci)
set -eu
SRC=$1; OUT=$2; CC=$3; ARCHS=$4; CFLAGS=$5
mkdir -p "$OUT"
make -C "$SRC" CC="$CC" ARCHS="$ARCHS" CFLAGS="$CFLAGS" \
  slib install-slib install-headers PREFIX="$OUT"
[ -f "$OUT/lib/libMacportsLegacySupport.a" ] || { echo "no static .a produced" >&2; exit 1; }
echo "legacy-support: $OUT/lib/libMacportsLegacySupport.a"
