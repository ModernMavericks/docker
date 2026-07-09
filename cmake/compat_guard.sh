#!/bin/sh
# 10.9 userland compat guard for one or more shipped Mach-O binaries.
# Per binary: (1) no post-10.9 UNDEFINED import, (2) arch exactly x86_64,
# (3) LC_VERSION_MIN_MACOSX == 10.9. Fail-closed if nothing measured.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd); . "$(dirname "$0")/common.sh"
# Post-10.9 APIs that must never appear as UNDEFINED imports. Families use a
# prefix (.*) so ALL members are caught, not just the ones we thought to list
# (e.g. _os_log_error_impl, _os_unfair_lock_trylock). Matched whole-symbol via grep -xE.
POST_10_9='_clock_gettime|_clock_gettime_nsec_np|_os_unfair_lock_.*|_os_log.*'
fail=0; checked=0
for b in "$@"; do
  [ -f "$b" ] || { echo "compat guard: MISSING $b" >&2; fail=1; continue; }
  checked=$((checked+1))
  # Static shim makes *at/clock_gettime DEFINED, so undefined-import scan stays clean.
  leak=$(nm -u "$b" 2>/dev/null | awk '{print $NF}' | grep -xE "($POST_10_9)" || true)
  [ -z "$leak" ] || { echo "compat guard: post-10.9 undefined import(s) in $b:" >&2; printf '%s\n' "$leak" | sed 's/^/  /' >&2; fail=1; }
  archs=$(lipo -info "$b" 2>/dev/null | sed 's/.*: //' || true)
  [ "$archs" = x86_64 ] || { echo "compat guard: $b arch '$archs' != x86_64" >&2; fail=1; }
  minos=$(otool -l "$b" 2>/dev/null | awk '/LC_VERSION_MIN_MACOSX/{f=1} f&&$1=="version"{print $2; exit}')
  [ "$minos" = 10.9 ] || { echo "compat guard: $b min-OS '$minos' != 10.9" >&2; fail=1; }
done
[ "$checked" -gt 0 ] || mvd_die "no binaries checked"
if [ "$fail" = 0 ]; then
  echo "compat guard: $checked binaries clean (x86_64, min-10.9, no post-10.9 imports)"
else
  exit 1
fi
