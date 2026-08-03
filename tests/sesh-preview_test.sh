#!/usr/bin/env bash

sesh_preview_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/sesh-preview"

function parse_name() {
  "$sesh_preview_path" --print-name "$@"
}

function test_strips_a_nerd_font_icon_and_space() {
  #  is the branch glyph sesh emits with --icons.
  assert_same "cli/_worktrees/grow-2742" "$(parse_name $' cli/_worktrees/grow-2742')"
}

function test_strips_an_emoji_icon() {
  assert_same "render" "$(parse_name "📦 render")"
}

function test_keeps_a_leading_tilde_path() {
  # The literal ~ is intentional: parse_name must not expand or strip it.
  # shellcheck disable=SC2088
  assert_same "~/repos/dotfiles" "$(parse_name $' ~/repos/dotfiles')"
}

function test_passes_through_a_bare_name_with_no_icon() {
  assert_same "dotfiles" "$(parse_name "dotfiles")"
}

function test_preserves_a_name_containing_spaces() {
  assert_same "my project/feature" "$(parse_name "📁 my project/feature")"
}

function test_strips_ansi_color_codes() {
  assert_same "dotfiles" "$(parse_name $'\033[34m\033[39m dotfiles')"
}
