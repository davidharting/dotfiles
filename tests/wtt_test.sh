#!/usr/bin/env bash

wtt_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/wtt"
wtt_base_args=$'switch\n--branches\n--prs\n--execute\ntat'

function set_up() {
  wtt_tmpdir="$(mktemp -d)"
  wtt_tmpdir="$(cd "$wtt_tmpdir" && pwd -P)"
  wtt_home="$wtt_tmpdir/home"
  wtt_fake_bin="$wtt_tmpdir/bin"

  mkdir -p \
    "$wtt_home/repos/render/api" \
    "$wtt_home/repos/api" \
    "$wtt_home/repos/dotfiles" \
    "$wtt_fake_bin"

  git -C "$wtt_home/repos/dotfiles" init -q
  git -C "$wtt_home/repos/dotfiles" config user.name "wtt test"
  git -C "$wtt_home/repos/dotfiles" config user.email "wtt-test@example.com"
  git -C "$wtt_home/repos/dotfiles" config commit.gpgsign false
  git -C "$wtt_home/repos/dotfiles" commit --allow-empty -q -m init
  git -C "$wtt_home/repos/dotfiles" branch -m main
  git -C "$wtt_home/repos/dotfiles" update-ref refs/remotes/origin/shared HEAD

  printf '#!/bin/sh\nprintf "%%s\\n" "$@"\n' >"$wtt_fake_bin/wt"
  chmod +x "$wtt_fake_bin/wt"
}

function tear_down() {
  rm -rf "$wtt_tmpdir"
}

function run_wtt() {
  HOME="$wtt_home" PATH="$wtt_fake_bin:$PATH" "$wtt_path" "$@"
}

function assert_wtt_output() {
  local expected="$1"
  shift

  local actual
  actual="$(run_wtt "$@")"

  assert_same "$expected" "$actual"
}

function capture_wtt() {
  if captured_stdout="$(run_wtt "$@" 2>"$wtt_tmpdir/stderr")"; then
    captured_status=0
  else
    captured_status=$?
  fi
  captured_stderr="$(<"$wtt_tmpdir/stderr")"
}

function test_prefers_the_render_repository_root() {
  assert_wtt_output \
    $'-C\n'"$wtt_home/repos/render/api"$'\n'"$wtt_base_args"$'\npr:123' \
    --repo api pr:123
}

function test_falls_back_to_the_general_repository_root() {
  rm -rf "$wtt_home/repos/render/api"

  assert_wtt_output \
    $'-C\n'"$wtt_home/repos/api"$'\n'"$wtt_base_args"$'\npr:123' \
    pr:123 --repo=api
}

function test_preserves_worktrunk_arguments() {
  assert_wtt_output \
    $'-C\n'"$wtt_home/repos/dotfiles"$'\n'"$wtt_base_args"$'\n--remotes' \
    --repo dotfiles --remotes
}

function test_opens_the_picker_without_arguments() {
  assert_wtt_output "$wtt_base_args"
}

function test_keeps_current_directory_behavior_without_a_repository() {
  assert_wtt_output \
    "$wtt_base_args"$'\npr:123' \
    pr:123
}

function test_switches_to_an_existing_local_branch() {
  assert_wtt_output \
    $'-C\n'"$wtt_home/repos/dotfiles"$'\n'"$wtt_base_args"$'\nmain' \
    --repo dotfiles main
}

function test_switches_to_an_existing_remote_branch() {
  assert_wtt_output \
    $'-C\n'"$wtt_home/repos/dotfiles"$'\n'"$wtt_base_args"$'\nshared' \
    --repo dotfiles shared
}

function test_creates_a_missing_explicit_branch_without_picker_arguments() {
  assert_wtt_output \
    $'-C\n'"$wtt_home/repos/dotfiles"$'\nswitch\n--create\n--execute\ntat\nfeature/new' \
    --repo dotfiles feature/new
}

function test_finds_the_branch_after_an_option_value() {
  assert_wtt_output \
    $'-C\n'"$wtt_home/repos/dotfiles"$'\nswitch\n--create\n--execute\ntat\n--base\nmain\nfeature/based' \
    --repo dotfiles --base main feature/based
}

function test_does_not_duplicate_an_explicit_create_flag() {
  assert_wtt_output \
    $'-C\n'"$wtt_home/repos/dotfiles"$'\nswitch\n--execute\ntat\n--create\nfeature/explicit' \
    --repo dotfiles --create feature/explicit
}

function test_preserves_the_current_worktree_shortcut() {
  assert_wtt_output \
    $'-C\n'"$wtt_home/repos/dotfiles"$'\n'"$wtt_base_args"$'\n@' \
    --repo dotfiles @
}

function test_rejects_an_unknown_repository() {
  capture_wtt --repo missing

  assert_same "1" "$captured_status"
  assert_empty "$captured_stdout"
  assert_contains "repository not found: missing" "$captured_stderr"
}

function test_rejects_a_missing_repository_name() {
  capture_wtt --repo

  assert_same "2" "$captured_status"
  assert_empty "$captured_stdout"
  assert_contains "--repo requires a repository name" "$captured_stderr"
}
