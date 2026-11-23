#!/usr/bin/env bash

tt_yeet_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/tt-yeet"

function set_up() {
  tt_yeet_tmpdir="$(mktemp -d)"
  tt_yeet_fake_bin="$tt_yeet_tmpdir/bin"
  tt_yeet_log="$tt_yeet_tmpdir/tmux.log"
  mkdir -p "$tt_yeet_fake_bin"

  # A fake tmux that logs every call. The caller is in session "main", window
  # 2. Any target containing "missing" fails the way tmux does.
  # shellcheck disable=SC2016
  printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "$*" >>"$TT_YEET_LOG"' \
    'case "$*" in *missing*) echo "can'"'"'t find it" >&2; exit 1 ;; esac' \
    'case "$1" in' \
    '  display-message)' \
    '    case "$5" in' \
    '      "#{session_name}:#{window_index}") echo main:2 ;;' \
    '      "#{pane_id}") echo %src ;;' \
    '    esac' \
    '    ;;' \
    '  list-panes)' \
    '    case "$*" in *-F*) printf "%s\n" %first %last ;; esac' \
    '    ;;' \
    'esac' >"$tt_yeet_fake_bin/tmux"
  chmod +x "$tt_yeet_fake_bin/tmux"
}

function tear_down() {
  rm -rf "$tt_yeet_tmpdir"
}

function run_tt_yeet() {
  TMUX_PANE=%caller TT_YEET_LOG="$tt_yeet_log" PATH="$tt_yeet_fake_bin:$PATH" \
    "$tt_yeet_path" "$@"
}

# Prints the source and destination targets tt-yeet looked up, one per line.
function resolved_targets() {
  : >"$tt_yeet_log"
  run_tt_yeet "$@" >/dev/null 2>&1
  awk '$1 == "list-panes" { print $3 }' "$tt_yeet_log"
}

function test_joins_source_beside_last_pane_of_target_window() {
  run_tt_yeet 1 3

  assert_same "join-pane -d -h -s %src -t %last" "$(tail -n 1 "$tt_yeet_log")"
}

function test_resolves_short_targets_against_the_callers_window() {
  assert_same $'main:2.1\nmain:3' "$(resolved_targets 1 3)"
  assert_same $'main:3.2\nmain:1' "$(resolved_targets 3.2 1)"
  assert_same $'work:4.1\nwork:3' "$(resolved_targets work:4.1 work:3)"
  assert_same $'%7\nmain:1' "$(resolved_targets %7 1)"
}

function test_moves_nothing_when_target_window_is_missing() {
  run_tt_yeet 1 missing 2>/dev/null
  local status=$?

  assert_same 1 "$status"
  assert_not_contains "join-pane" "$(cat "$tt_yeet_log")"
}

function test_moves_nothing_when_source_pane_is_missing() {
  run_tt_yeet missing 3 2>/dev/null
  local status=$?

  assert_same 1 "$status"
  assert_not_contains "join-pane" "$(cat "$tt_yeet_log")"
}

function test_rejects_wrong_argument_count() {
  run_tt_yeet 1 >/dev/null 2>&1
  local status=$?

  assert_same 2 "$status"
}
