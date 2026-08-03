#!/usr/bin/env bash

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/herdr/.config/herdr/plugins-local/last-tab"

function set_up() {
  last_tab_tmpdir="$(mktemp -d)"
  last_tab_state_dir="$last_tab_tmpdir/state"
  last_tab_log="$last_tab_tmpdir/herdr.log"
  last_tab_fake_herdr="$last_tab_tmpdir/herdr"

  mkdir -p "$last_tab_state_dir"
  # Variables belong to the generated fake script.
  # shellcheck disable=SC2016
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >>"$HERDR_TEST_LOG"\n' >"$last_tab_fake_herdr"
  chmod +x "$last_tab_fake_herdr"
}

function tear_down() {
  rm -rf "$last_tab_tmpdir"
}

function focus_event() {
  local tab_id="$1"
  local event
  event="$(
    jq -cn --arg tab_id "$tab_id" \
      '{
        event: "tab_focused",
        data: {type: "tab_focused", workspace_id: "w1", tab_id: $tab_id}
      }'
  )"
  HERDR_PLUGIN_STATE_DIR="$last_tab_state_dir" \
    HERDR_PLUGIN_EVENT_JSON="$event" \
    "$plugin_dir/track-focus.sh"
}

function workspace_focus_event() {
  local workspace_id="$1"
  local event
  event="$(
    jq -cn --arg workspace_id "$workspace_id" \
      '{
        event: "workspace_focused",
        data: {
          type: "workspace_focused",
          workspace_id: $workspace_id
        }
      }'
  )"
  HERDR_PLUGIN_STATE_DIR="$last_tab_state_dir" \
    HERDR_PLUGIN_EVENT_JSON="$event" \
    "$plugin_dir/track-focus.sh"
}

function test_tracks_the_previously_focused_tab() {
  focus_event w1:t1
  focus_event w1:t2

  assert_same \
    '{"current":"w1:t2","previous":"w1:t1"}' \
    "$(jq -c '.w1' "$last_tab_state_dir/tabs.json")"
}

function test_focus_action_targets_the_previous_tab() {
  printf '%s\n' \
    '{"w1":{"current":"w1:t2","previous":"w1:t1"}}' \
    >"$last_tab_state_dir/tabs.json"

  HERDR_BIN_PATH="$last_tab_fake_herdr" \
    HERDR_TEST_LOG="$last_tab_log" \
    HERDR_PLUGIN_STATE_DIR="$last_tab_state_dir" \
    HERDR_WORKSPACE_ID=w1 \
    HERDR_TAB_ID=w1:t2 \
    "$plugin_dir/last-tab.sh"

  assert_same \
    $'tab get w1:t1\ntab focus w1:t1' \
    "$(<"$last_tab_log")"
}

function test_tracks_and_focuses_the_previous_workspace() {
  workspace_focus_event w1
  workspace_focus_event w2

  HERDR_BIN_PATH="$last_tab_fake_herdr" \
    HERDR_TEST_LOG="$last_tab_log" \
    HERDR_PLUGIN_STATE_DIR="$last_tab_state_dir" \
    HERDR_WORKSPACE_ID=w2 \
    "$plugin_dir/last-workspace.sh"

  assert_same \
    $'workspace get w1\nworkspace focus w1' \
    "$(<"$last_tab_log")"
}
