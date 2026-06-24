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

  if "$@" >"$tmpdir/stdout" 2>"$tmpdir/stderr"; then
    printf 'FAIL: %s\ncommand unexpectedly succeeded\n' "$message" >&2
    exit 1
  fi

  if ! grep -q 'Usage: lineardir ISSUE-123' "$tmpdir/stderr"; then
    printf 'FAIL: %s\nexpected usage text on stderr\nstderr:\n%s\n' "$message" "$(cat "$tmpdir/stderr")" >&2
    exit 1
  fi
}

home="$tmpdir/home"
mkdir -p "$home"

expected="$home/repos/control-room/scratch/linear/grow-1234"
actual="$(HOME="$home" "$script" GROW-1234)"
assert_eq "$expected" "$actual" "prints lowercased issue directory"
assert_dir_exists "$expected"

assert_fails "requires exactly one argument" env HOME="$home" "$script"
assert_fails "rejects one-letter project keys" env HOME="$home" "$script" G-123
assert_fails "rejects missing numeric suffix" env HOME="$home" "$script" GROW-
assert_fails "rejects missing literal dash" env HOME="$home" "$script" GROW123
assert_fails "rejects non-numeric suffix" env HOME="$home" "$script" GROW-ABC

printf 'lineardir tests passed\n'
