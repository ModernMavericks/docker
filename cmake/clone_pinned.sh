#!/bin/sh
# Idempotently clone a pinned tag into a shared, mode/host-independent cache dir so the
# (large) checkout is downloaded once and reused across build dirs and hosts.
# Args: REPO REF DEST. No-op if DEST already holds the checkout.
# Note: ExternalProject pre-creates DEST (empty) before the download step, so we clone
# to a temp sibling and atomically replace DEST (rename) -- never mv into it.
set -eu
REPO=$1; REF=$2; DEST=$3
if [ -d "$DEST/.git" ]; then
  echo "src cache hit: $DEST"
else
  mkdir -p "$(dirname "$DEST")"
  tmp="$DEST.tmp.$$"
  rm -rf "$tmp"
  git clone --depth 1 --branch "$REF" "$REPO" "$tmp"
  rm -rf "$DEST"       # drop the empty dir ExternalProject pre-created (or a stale partial)
  mv "$tmp" "$DEST"
  echo "src cached: $DEST"
fi
