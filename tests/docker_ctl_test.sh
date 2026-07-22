#!/bin/sh
# Unit tests for docker-machine-ctl verbs via PATH stubs.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CTL="$ROOT/payload/docker-machine-ctl"
[ -f "$CTL" ] || { echo "docker_ctl_test: ctl missing" >&2; exit 1; }
fail() { echo "docker_ctl_test: FAIL: $*" >&2; exit 1; }

setup() {
  WORK=$(mktemp -d "${TMPDIR:-/tmp}/container-tools-ctl.XXXXXX")
  BIN="$WORK/bin"; mkdir -p "$BIN"
  export HOME="$WORK/home"; mkdir -p "$HOME"
  export MAVERICKS_DOCKER_STATE_DIR="$WORK/state"
  export MAVERICKS_DOCKER_LOG="$WORK/log"
  export MAVERICKS_DOCKER_FUSION_PRESENT=1
  export MAVERICKS_DOCKER_COMMON="$ROOT/payload/docker-machine-common.sh"
  export DM_LOG="$WORK/dm.args"; : > "$DM_LOG"
  export LC_LOG="$WORK/lc.args"; : > "$LC_LOG"
  OLDPATH=$PATH; PATH="$BIN:$PATH"
}
teardown() { PATH=$OLDPATH; rm -rf "$WORK"; }

stub_dm() { # $1 = status word
  cat > "$BIN/docker-machine" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$DM_LOG"
[ "\$1" = status ] && { echo "$1"; exit 0; }
exit 0
EOF
  chmod +x "$BIN/docker-machine"
}
stub_launchctl() { # $1 = exit code for "list" (0 = loaded/on, 1 = not loaded/off)
  cat > "$BIN/launchctl" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$LC_LOG"
case "\$1" in list) exit $1 ;; *) exit 0 ;; esac
EOF
  chmod +x "$BIN/launchctl"
}

case_status() {
  setup; stub_dm Running
  [ "$(sh "$CTL" status)" = running ] || fail "status running"
  [ "$(cat "$MAVERICKS_DOCKER_STATE_DIR/state")" = running ] || fail "status writes state"
  teardown
}
case_start_stop() {
  setup; stub_dm Running
  sh "$CTL" start >/dev/null || fail "start exit 0"
  grep -q '^start default' "$DM_LOG" || fail "start calls docker-machine start default"
  sh "$CTL" stop >/dev/null || fail "stop exit 0"
  grep -q '^stop default' "$DM_LOG" || fail "stop calls docker-machine stop default"
  teardown
}
case_login() {
  setup; stub_launchctl 0
  [ "$(sh "$CTL" login-status)" = on ] || fail "loaded -> on"
  stub_launchctl 1
  [ "$(sh "$CTL" login-status)" = off ] || fail "not loaded -> off"
  sh "$CTL" login-on >/dev/null
  grep -q 'load -w /Library/LaunchAgents/dev.modernmavericks.container-tools-machine.plist' "$LC_LOG" || fail "login-on loads the plist"
  sh "$CTL" login-off >/dev/null
  grep -q 'unload -w /Library/LaunchAgents/dev.modernmavericks.container-tools-machine.plist' "$LC_LOG" || fail "login-off unloads the plist"
  teardown
}
case_vmxpid() {
  setup
  cat > "$BIN/pgrep" <<'EOF'
#!/bin/sh
echo 4242
EOF
  chmod +x "$BIN/pgrep"
  [ "$(sh "$CTL" vmx-pid)" = 4242 ] || fail "vmx-pid prints the pid"
  teardown
}
case_setup() {
  setup
  cat > "$BIN/docker-machine-bootstrap" <<EOF
#!/bin/sh
: > "$WORK/bootstrap-ran"
EOF
  chmod +x "$BIN/docker-machine-bootstrap"
  sh "$CTL" setup || fail "setup exit 0"
  [ -f "$WORK/bootstrap-ran" ] || fail "setup execs docker-machine-bootstrap"
  teardown
}

case_status
case_start_stop
case_login
case_vmxpid
case_setup
echo "docker_ctl_test: OK"
