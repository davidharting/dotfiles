#!/usr/bin/env bash

pr_body_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/pr-body"

function set_up() {
  pr_body_tmpdir="$(mktemp -d)"
  pr_body_fake_bin="$pr_body_tmpdir/bin"
  pr_body_editor_copy="$pr_body_tmpdir/editor-copy"
  mkdir -p "$pr_body_fake_bin"

  printf '#!/bin/sh\nprintf "first\\r\\nsecond\\r\\n"\n' >"$pr_body_fake_bin/gh"
  printf "#!/bin/sh\ncp \"\$1\" \"\$PR_BODY_EDITOR_COPY\"\n" >"$pr_body_fake_bin/editor"
  chmod +x "$pr_body_fake_bin/gh" "$pr_body_fake_bin/editor"
}

function tear_down() {
  rm -rf "$pr_body_tmpdir"
}

function test_normalizes_github_crlf_before_opening_the_editor() {
  PATH="$pr_body_fake_bin:$PATH" \
    EDITOR="$pr_body_fake_bin/editor" \
    PR_BODY_EDITOR_COPY="$pr_body_editor_copy" \
    "$pr_body_path"

  local actual
  actual="$(od -An -tx1 "$pr_body_editor_copy" | tr -d ' \n')"

  assert_same "66697273740a7365636f6e640a" "$actual"
}
