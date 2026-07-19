#!/bin/sh
# Shared helpers for build + gate scripts. POSIX sh; no bashisms.
# mvd_mode: "native" on the real 10.9 machine (pkgsrc go126 present), else "cross".
mvd_mode() {
  if [ -x /opt/pkg/go126/bin/go ] && [ "$(uname -s)" = Darwin ] \
     && sw_vers -productVersion 2>/dev/null | grep -q '^10\.9\.'; then
    echo native
  else
    echo cross
  fi
}

# mvd_die <msg...>: fail-closed helper for gates.
mvd_die() { echo "CANNOT MEASURE (fail-closed): $*" >&2; exit 4; }
