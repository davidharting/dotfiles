#!/usr/bin/env bash

hat_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/hat"

function set_up() {
  hat_tmpdir="$(mktemp -d)"
  hat_tmpdir="$(cd "$hat_tmpdir" && pwd -P)"
  hat_home="$hat_tmpdir/home"
  hat_repo="$hat_home/repos/project"
  hat_worktree="$hat_repo/.wt/feature"
  hat_fake_bin="$hat_tmpdir/bin"
  hat_log="$hat_tmpdir/herdr.log"

  mkdir -p "$hat_repo" "$hat_fake_bin"
  git -C "$hat_repo" init -q
  git -C "$hat_repo" config user.name "hat test"
  git -C "$hat_repo" config user.email "hat-test@example.com"
  git -C "$hat_repo" config commit.gpgsign false
  git -C "$hat_repo" commit --allow-empty -q -m init
  git -C "$hat_repo" worktree add -q -b feature "$hat_worktree"

  # Variables belong to the generated fake script.
  # shellcheck disable=SC2016
  printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "$*" >>"$HERDR_TEST_LOG"' \
    'if [ "$1 $2" = "worktree open" ]; then' \
    '  printf "%s\n" '\''{"result":{"already_open":false,"workspace":{"workspace_id":"w2"},"tab":{"tab_id":"w2:t1"}}}'\''' \
    'fi' \
    >"$hat_fake_bin/herdr"
  chmod +x "$hat_fake_bin/herdr"
}

function tear_down() {
  rm -rf "$hat_tmpdir"
}

function test_registers_a_worktrunk_checkout_as_a_native_herdr_worktree() {
  (
    cd "$hat_worktree" || exit
    HOME="$hat_home" \
      HERDR_ENV=1 \
      HERDR_TEST_LOG="$hat_log" \
      PATH="$hat_fake_bin:$PATH" \
      "$hat_path"
  )

  assert_same \
    "worktree open --path $hat_worktree --focus --json" \
    "$(sed -n '1p' "$hat_log")"
  assert_not_contains "workspace create" "$(<"$hat_log")"
  assert_contains "tab rename w2:t1 🖥️ nvim" "$(<"$hat_log")"
  assert_contains "tab create --workspace w2 --label 🤖 clankers --no-focus" "$(<"$hat_log")"
}
