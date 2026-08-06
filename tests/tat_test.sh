#!/usr/bin/env bash

tat_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/tat"

function set_up() {
  tat_tmpdir="$(mktemp -d)"
  tat_tmpdir="$(cd "$tat_tmpdir" && pwd -P)"
  tat_fake_bin="$tat_tmpdir/bin"
  tat_project="$tat_tmpdir/project"

  mkdir -p "$tat_fake_bin" "$tat_project"

  # These are intentionally literal lines in the fake tmux executable.
  # shellcheck disable=SC2016
  printf '%s\n' \
    '#!/bin/sh' \
    'case "$1" in' \
    '  list-sessions)' \
    '    if [ "${TAT_TEST_EXISTING:-0}" = 1 ]; then' \
    '      printf "%s\t%s\n" "$PWD" existing' \
    '    fi' \
    '    ;;' \
    '  list-clients)' \
    '    if [ "${TAT_TEST_CLIENTS:-0}" = 1 ]; then' \
    '      printf "%s\n" /dev/ttys998 /dev/ttys999' \
    '    fi' \
    '    ;;' \
    '  detach-client)' \
    '    printf "%s\n" "$@"' \
    '    ;;' \
    'esac' >"$tat_fake_bin/tmux"

  printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "$@"' >"$tat_fake_bin/sesh"

  chmod +x "$tat_fake_bin/tmux" "$tat_fake_bin/sesh"
}

function tear_down() {
  rm -rf "$tat_tmpdir"
}

function run_tat_outside_tmux() {
  (
    cd "$tat_project" || exit
    env -u TMUX PATH="$tat_fake_bin:$PATH" "$tat_path"
  )
}

function run_tat_inside_tmux() {
  (
    cd "$tat_project" || exit
    TMUX=/tmp/tmux-test,1,0 PATH="$tat_fake_bin:$PATH" "$tat_path"
  )
}

function test_replaces_existing_clients_when_invoked_outside_tmux() {
  assert_same \
    $'detach-client\n-t\n/dev/ttys998\ndetach-client\n-t\n/dev/ttys999\nconnect\nexisting' \
    "$(TAT_TEST_EXISTING=1 TAT_TEST_CLIENTS=1 run_tat_outside_tmux)"
}

function test_attaches_when_no_tmux_client_exists() {
  assert_same \
    $'connect\n'"$tat_project" \
    "$(run_tat_outside_tmux)"
}

function test_lets_sesh_switch_the_current_client_when_inside_tmux() {
  assert_same \
    $'connect\nexisting' \
    "$(TAT_TEST_EXISTING=1 TAT_TEST_CLIENTS=1 run_tat_inside_tmux)"
}
