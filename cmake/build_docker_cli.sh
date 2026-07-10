#!/bin/sh
# Build docker/cli -> $OUT/docker (x86_64, min-10.9, static shim). Called by the
# docker_cli ExternalProject: inputs absolute/explicit, no host detection, no clone. Args:
#   $1 SRC        absolute cloned source dir
#   $2 OUT        absolute output dir (binary -> $OUT/docker)
#   $3 GO         go binary
#   $4 CC         C compiler
#   $5 ARCH_FLAGS "" on box; "-arch x86_64" on ci
#   $6 SDK_FLAGS  "" on box; "-isysroot <sdk>" on ci
#   $7 LS_A       absolute path to libMacportsLegacySupport.a
#   $8 REF        docker/cli tag (VERSION = ${REF#v})
set -eu
SRC=$1; OUT=$2; GO=$3; CC=$4; ARCH_FLAGS=$5; SDK_FLAGS=$6; LS_A=$7; REF=$8
VER=${REF#v}
mkdir -p "$OUT"
cd "$SRC"
ln -sf vendor.mod go.mod
ln -sf vendor.sum go.sum
# On NFS, macOS stores xattrs as AppleDouble sidecars; untracked ._go.* files
# make git report the pinned clone dirty and Go stamps ".dirty" into Version.
rm -f ._go.mod ._go.sum
COMMIT=$(git rev-parse --short HEAD)
export CGO_ENABLED=1 CC GOARCH=amd64
export CGO_CFLAGS="-mmacosx-version-min=10.9 $ARCH_FLAGS $SDK_FLAGS"
# Shim goes in ONCE via -extldflags (as in the other Go components): CGO_LDFLAGS is
# recorded per cgo package, so the archive lands on the link line repeatedly and
# modern ld warns about duplicate libraries.
export CGO_LDFLAGS="-mmacosx-version-min=10.9 $ARCH_FLAGS $SDK_FLAGS -Wl,-undefined,dynamic_lookup"
"$GO" build -mod=vendor \
  -ldflags "-linkmode=external -extldflags \"$LS_A\" \
            -X github.com/docker/cli/cli/version.Version=$VER \
            -X github.com/docker/cli/cli/version.GitCommit=$COMMIT \
            -X github.com/docker/cli/cli/version.BuildTime=mavericks-$("$GO" version | awk '{print $3}')" \
  -o "$OUT/docker" ./cmd/docker
[ -f "$OUT/docker" ] || { echo "no docker binary produced" >&2; exit 1; }
echo "docker-cli: $OUT/docker"
