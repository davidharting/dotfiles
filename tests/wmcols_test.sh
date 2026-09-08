#!/usr/bin/env bash

wmcols_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/wmcols"

function set_up() {
  wmcols_tmpdir="$(mktemp -d)"
  wmcols_tmpdir="$(cd "$wmcols_tmpdir" && pwd -P)"
  wmcols_fake_bin="$wmcols_tmpdir/bin"
  mkdir -p "$wmcols_fake_bin"

  # Stub state: one window id per line, in strip order, plus the focused id and
  # a log of the commands wmcols issued.
  printf 'w1\nw2\nw3\n' >"$wmcols_tmpdir/windows"
  printf 'w1\n' >"$wmcols_tmpdir/focus"
  printf '1\n' >"$wmcols_tmpdir/workspace"
  : >"$wmcols_tmpdir/log"

  write_stub
}

function tear_down() {
  rm -rf "$wmcols_tmpdir"
}

# A stand-in for omniwmctl that tracks focus across invocations. `focus right`
# stops at the last window unless WMCOLS_TEST_WRAP is set.
function write_stub() {
  cat >"$wmcols_fake_bin/omniwmctl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
dir="$WMCOLS_TEST_DIR"
echo "$*" >>"$dir/log"

[[ -f $dir/unreachable ]] && exit 1

case "$1 ${2:-}" in
  "ping ")
    exit 0
    ;;
  "query workspaces")
    printf 'ID\tWORKSPACE\tDISPLAY\tLAYOUT\tCURRENT\tVISIBLE\n'
    current="$(cat "$dir/workspace")"
    for ws in 1 2 3 4; do
      marker=no
      [[ $ws == "$current" ]] && marker=yes
      printf 'id%s\t%s\tMon\tniri\t%s\tyes\n' "$ws" "$ws" "$marker"
    done
    ;;
  "command switch-workspace")
    printf '%s\n' "$3" >"$dir/workspace"
    ;;
  "query windows")
    printf 'ID\tPID\tAPP\tTITLE\tWORKSPACE\tDISPLAY\tMODE\tFOCUSED\tVISIBLE\n'
    focus="$(cat "$dir/focus")"
    while read -r id; do
      marker=no
      [[ $id == "$focus" ]] && marker=yes
      printf '%s\t1\tApp\tt\t1\tMon\ttiling\t%s\tyes\n' "$id" "$marker"
    done <"$dir/windows"
    ;;
  "command focus-column")
    head -n 1 "$dir/windows" >"$dir/focus"
    ;;
  "command focus")
    focus="$(cat "$dir/focus")"
    next="$(awk -v cur="$focus" '$0 == cur { getline; print; exit }' "$dir/windows")"
    if [[ -n $next ]]; then
      printf '%s\n' "$next" >"$dir/focus"
    elif [[ -n ${WMCOLS_TEST_WRAP:-} ]]; then
      head -n 1 "$dir/windows" >"$dir/focus"
    fi
    ;;
  "window focus")
    printf '%s\n' "$3" >"$dir/focus"
    ;;
esac
STUB
  chmod +x "$wmcols_fake_bin/omniwmctl"
}

function run_wmcols() {
  WMCOLS_TEST_DIR="$wmcols_tmpdir" \
    WMCOLS_SETTLE_TIMEOUT=1 \
    PATH="$wmcols_fake_bin:$PATH" \
    "$wmcols_path" "$@"
}

function capture_wmcols() {
  if captured_stdout="$(run_wmcols "$@" 2>"$wmcols_tmpdir/stderr")"; then
    captured_status=0
  else
    captured_status=$?
  fi
  captured_stderr="$(<"$wmcols_tmpdir/stderr")"
}

function test_rejects_a_missing_argument() {
  capture_wmcols
  assert_same 1 "$captured_status"
  assert_contains "Usage: wmcols N" "$captured_stderr"
}

function test_rejects_a_non_numeric_argument() {
  capture_wmcols abc
  assert_same 1 "$captured_status"
  assert_contains "Usage: wmcols N" "$captured_stderr"
}

function test_rejects_zero() {
  capture_wmcols 0
  assert_same 1 "$captured_status"
}

function test_reports_an_unreachable_window_manager() {
  touch "$wmcols_tmpdir/unreachable"
  capture_wmcols 2
  assert_same 1 "$captured_status"
  assert_contains "not responding" "$captured_stderr"
}

function test_reports_when_no_window_is_focused() {
  : >"$wmcols_tmpdir/focus"
  capture_wmcols 2
  assert_same 1 "$captured_status"
  assert_contains "no focused window" "$captured_stderr"
}

function test_sizes_every_column_and_reports_the_count() {
  capture_wmcols 2
  assert_same 0 "$captured_status"
  assert_same \
    "wmcols: set 3 column(s) to 50% each -- 2 visible at a time, rest scrolled off" \
    "$captured_stdout"
  assert_same 3 "$(grep -c 'set-container-primary-span 50%' "$wmcols_tmpdir/log")"
}

function test_omits_the_scrolled_off_note_when_everything_fits() {
  capture_wmcols 3
  assert_same \
    "wmcols: set 3 column(s) to 33% each -- 3 visible at a time" \
    "$captured_stdout"
}

function test_restores_the_original_focus() {
  printf 'w2\n' >"$wmcols_tmpdir/focus"
  capture_wmcols 2
  assert_same "w2" "$(cat "$wmcols_tmpdir/focus")"
  assert_same "window focus w2" "$(tail -n 1 "$wmcols_tmpdir/log")"
}

function test_stops_when_focus_wraps_around() {
  # Without the already-sized check, a wrapping focus would size columns until
  # the loop bound instead of stopping after one pass.
  WMCOLS_TEST_WRAP=1 capture_wmcols 2
  assert_same 3 "$(grep -c 'set-container-primary-span' "$wmcols_tmpdir/log")"
}

function test_rejects_a_non_numeric_workspace() {
  capture_wmcols 2 abc
  assert_same 1 "$captured_status"
  assert_contains "Usage: wmcols N" "$captured_stderr"
}

function test_rejects_extra_arguments() {
  capture_wmcols 2 3 4
  assert_same 1 "$captured_status"
}

function test_visits_the_target_workspace_and_returns() {
  capture_wmcols 2 3
  assert_same 0 "$captured_status"
  assert_same "1" "$(cat "$wmcols_tmpdir/workspace")"
  assert_contains "switch-workspace 3" "$(cat "$wmcols_tmpdir/log")"
}

function test_does_not_switch_when_already_on_the_target() {
  capture_wmcols 2 1
  assert_same 0 "$captured_status"
  assert_same 0 "$(grep -c 'switch-workspace' "$wmcols_tmpdir/log")"
}

function test_returns_home_when_the_target_cannot_be_sized() {
  # The no-focus guard exits early, after the switch has already happened.
  : >"$wmcols_tmpdir/focus"
  capture_wmcols 2 4
  assert_same 1 "$captured_status"
  assert_same "1" "$(cat "$wmcols_tmpdir/workspace")"
}
