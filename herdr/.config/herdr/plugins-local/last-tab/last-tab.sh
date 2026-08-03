#!/usr/bin/env bash
set -euo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
workspace_id="${HERDR_WORKSPACE_ID:?}"
current_tab_id="${HERDR_TAB_ID:?}"
state_file="${HERDR_PLUGIN_STATE_DIR:?}/tabs.json"
target=""

if [[ -s "$state_file" ]]; then
  target="$(
    jq -r --arg workspace "$workspace_id" \
      '.[$workspace].previous // empty' "$state_file"
  )"
fi

if [[ -n "$target" && "$target" != "$current_tab_id" ]] \
  && "$herdr_bin" tab get "$target" >/dev/null 2>&1; then
  "$herdr_bin" tab focus "$target" >/dev/null
  exit 0
fi

# The plugin cannot recover focus history from before it was linked. On the
# first invocation only, bootstrap from the preceding positional tab; focus
# events make subsequent invocations a true two-tab toggle.
tabs="$("$herdr_bin" tab list --workspace "$workspace_id")"
target="$(
  jq -r --arg current "$current_tab_id" '
    .result.tabs as $tabs
    | ($tabs | map(.tab_id) | index($current)) as $index
    | if ($index == null or ($tabs | length) < 2) then
        empty
      elif $index == 0 then
        $tabs[-1].tab_id
      else
        $tabs[$index - 1].tab_id
      end
  ' <<<"$tabs"
)"

if [[ -n "$target" && "$target" != "$current_tab_id" ]]; then
  "$herdr_bin" tab focus "$target" >/dev/null
fi
