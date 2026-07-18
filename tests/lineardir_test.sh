#!/usr/bin/env bash

lineardir_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/lineardir"

function set_up() {
  lineardir_tmpdir="$(mktemp -d)"
  lineardir_home="$lineardir_tmpdir/home"
  mkdir -p "$lineardir_home"
}

function tear_down() {
  rm -rf "$lineardir_tmpdir"
}

function run_lineardir() {
  HOME="$lineardir_home" "$lineardir_path" "$@"
}

function assert_issue_directory() {
  local expected="$1"
  shift

  local actual
  actual="$(run_lineardir "$@")"

  assert_same "$expected" "$actual"
  assert_directory_exists "$expected"
}

function assert_rejected() {
  local output
  local status

  if output="$(run_lineardir "$@" 2>&1)"; then
    status=0
  else
    status=$?
  fi

  assert_same "2" "$status"
  assert_contains "Usage:" "$output"
}

function test_prints_a_lowercase_issue_directory() {
  assert_issue_directory \
    "$lineardir_home/repos/control-room/scratch/linear/grow-1234" \
    GROW-1234
}

function test_accepts_a_lowercase_team_and_number() {
  assert_issue_directory \
    "$lineardir_home/repos/control-room/scratch/linear/grow-2511" \
    grow 2511
}

function test_accepts_an_uppercase_team_and_number() {
  assert_issue_directory \
    "$lineardir_home/repos/control-room/scratch/linear/teams-9000" \
    TEAMS 9000
}

function test_accepts_a_lowercase_hyphenated_key() {
  assert_issue_directory \
    "$lineardir_home/repos/control-room/scratch/linear/grow-2511" \
    grow-2511
}

function test_both_input_forms_produce_the_same_directory() {
  local separate
  local hyphenated

  separate="$(run_lineardir GROW 1234)"
  hyphenated="$(run_lineardir GROW-1234)"

  assert_same "$separate" "$hyphenated"
}

function test_rejects_zero_arguments() {
  assert_rejected
}

function test_rejects_letters_as_the_issue_number() {
  assert_rejected TEAM abc
}

function test_rejects_a_one_letter_team_prefix() {
  assert_rejected A 123
}

function test_rejects_three_arguments() {
  assert_rejected GROW-123 extra arg
}

function test_rejects_a_one_letter_team_in_a_hyphenated_key() {
  assert_rejected G-123
}

function test_rejects_a_missing_numeric_suffix() {
  assert_rejected GROW-
}

function test_rejects_a_missing_dash() {
  assert_rejected GROW123
}

function test_rejects_a_non_numeric_hyphenated_suffix() {
  assert_rejected TEAMS-ABC
}

function test_rejects_an_empty_separate_issue_number() {
  assert_rejected TEAM ""
}
