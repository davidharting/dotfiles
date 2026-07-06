#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/lineardir"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_dir_exists() {
  local dir="$1"

  if [[ ! -d "$dir" ]]; then
    printf 'FAIL: expected directory to exist: %s\n' "$dir" >&2
    exit 1
  fi
}

assert_fails() {
  local message="$1"
  shift
  # Remaining args are the command + its arguments
  if "$@" >"$tmpdir/stdout" 2>"$tmpdir/stderr"; then
    printf 'FAIL: %s\ncommand unexpectedly succeeded\n' "$message" >&2
    exit 1
  fi

  if ! grep -q 'Usage:' "$tmpdir/stderr"; then
    printf 'FAIL: %s\nexpected usage text on stderr\nstderr:\n%s\n' "$message" "$(cat "$tmpdir/stderr")" >&2
    exit 1
  fi
}

home="$tmpdir/home"
mkdir -p "$home"

# --- Original single-argument tests ---
expected="$home/repos/control-room/scratch/linear/grow-1234"
actual="$(HOME="$home" "$script" GROW-1234)"
assert_eq "$expected" "$actual" "prints lowercased issue directory"
assert_dir_exists "$expected"

# --- New two-argument tests ---
expected="$home/repos/control-room/scratch/linear/grow-2511"
actual="$(HOME="$home" "$script" grow 2511)"
assert_eq "$expected" "$actual" "two-arg form: lowercase team + number"
assert_dir_exists "$expected"

expected="$home/repos/control-room/scratch/linear/teams-9000"
actual="$(HOME="$home" "$script" TEAMS 9000)"
assert_eq "$expected" "$actual" "two-arg form: uppercase team + number"
assert_dir_exists "$expected"

# --- New hyphenated single-argument tests ---
expected="$home/repos/control-room/scratch/linear/grow-2511"
actual="$(HOME="$home" "$script" grow-2511)"
assert_eq "$expected" "$actual" "hyphenated single-arg form works"
assert_dir_exists "$expected"

# --- Ensure both forms produce the same directory ---
dir_one="$(HOME="$home" "$script" GROW 1234)"
dir_two="$(HOME="$home" "$script" GROW-1234)"
assert_eq "$dir_one" "$dir_two" "two-arg and hyphenated-single-arg produce identical dirs"

# --- Invalid argument tests ---
assert_fails "rejects zero arguments" env HOME="$home" "$script"
assert_fails "rejects invalid two-arg number (letters)" env HOME="$home" "$script" TEAM abc
assert_fails "rejects one-letter team prefix" env HOME="$home" "$script" A 123
assert_fails "rejects three arguments" env HOME="$home" "$script" GROW-123 extra arg
assert_fails "rejects one-letter project keys in single-arg form" env HOME="$home" "$script" G-123
assert_fails "rejects missing numeric suffix" env HOME="$home" "$script" GROW-
assert_fails "rejects missing literal dash" env HOME="$home" "$script" GROW123
assert_fails "rejects non-numeric suffix in single-arg form" env HOME="$home" "$script" TEAMS-ABC
assert_fails "rejects empty two-argument number" env HOME="$home" "$script" TEAM ""


printf 'lineardir tests passed\n'
