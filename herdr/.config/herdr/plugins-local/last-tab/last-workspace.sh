#!/usr/bin/env bash
set -euo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
current_workspace_id="${HERDR_WORKSPACE_ID:?}"
state_file="${HERDR_PLUGIN_STATE_DIR:?}/tabs.json"
target=""

if [[ -s "$state_file" ]]; then
  target="$(jq -r '._workspace.previous // empty' "$state_file")"
fi

if [[ -n "$target" && "$target" != "$current_workspace_id" ]] \
  && "$herdr_bin" workspace get "$target" >/dev/null 2>&1; then
  "$herdr_bin" workspace focus "$target" >/dev/null
  exit 0
fi

# Bootstrap from the preceding positional workspace when no focus event has
# been recorded yet. Subsequent invocations use true focus history.
workspaces="$("$herdr_bin" workspace list)"
target="$(
  jq -r --arg current "$current_workspace_id" '
    .result.workspaces as $workspaces
    | ($workspaces | map(.workspace_id) | index($current)) as $index
    | if ($index == null or ($workspaces | length) < 2) then
        empty
      elif $index == 0 then
        $workspaces[-1].workspace_id
      else
        $workspaces[$index - 1].workspace_id
      end
  ' <<<"$workspaces"
)"

if [[ -n "$target" && "$target" != "$current_workspace_id" ]]; then
  "$herdr_bin" workspace focus "$target" >/dev/null
fi
