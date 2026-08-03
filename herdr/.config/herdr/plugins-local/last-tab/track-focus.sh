#!/usr/bin/env bash
set -euo pipefail

state_dir="${HERDR_PLUGIN_STATE_DIR:?}"
state_file="$state_dir/tabs.json"
lock_dir="$state_dir/tabs.lock"
event="${HERDR_PLUGIN_EVENT_JSON:-}"
[[ -n "$event" ]] || event='{}'
# Herdr 0.7.5 can inject this through more than one JSON-string layer. Unwrap
# strings until the event object is reached, while accepting a decoded object
# for forward compatibility.
raw_event="$event"
for _ in {1..4}; do
  [[ "$(jq -r 'type' <<<"$event")" == string ]] || break
  event="$(jq -r 'fromjson' <<<"$event")"
done
if [[ "$(jq -r 'type' <<<"$event")" != object ]]; then
  printf 'last-tab: unexpected event payload: %s\n' "$raw_event" >&2
  exit 1
fi
event="$(jq -c '.data // .' <<<"$event")"

mkdir -p "$state_dir"

# Event hooks can overlap. An atomic mkdir is sufficient for this tiny critical
# section and keeps the plugin dependency-free on macOS.
locked=false
for _ in {1..100}; do
  if mkdir "$lock_dir" 2>/dev/null; then
    locked=true
    trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT
    break
  fi
  sleep 0.01
done
[[ "$locked" == true ]] || exit 1

if [[ -s "$state_file" ]]; then
  state="$(<"$state_file")"
else
  state='{}'
fi

event_type="$(jq -r '.type // empty' <<<"$event")"
workspace_id="$(jq -r '.workspace_id // empty' <<<"$event")"

case "$event_type" in
  tab_focused)
    tab_id="$(jq -r '.tab_id // empty' <<<"$event")"
    updated="$(
      jq -c --arg workspace "$workspace_id" --arg tab "$tab_id" '
        if ((.[$workspace].current // "") == $tab) then
          .
        else
          .[$workspace] = {
            current: $tab,
            previous: (.[$workspace].current // null)
          }
        end
      ' <<<"$state"
    )"
    ;;
  tab_closed)
    tab_id="$(jq -r '.tab_id // empty' <<<"$event")"
    updated="$(
      jq -c --arg workspace "$workspace_id" --arg tab "$tab_id" '
        if ((.[$workspace].previous // "") == $tab) then
          .[$workspace].previous = null
        elif ((.[$workspace].current // "") == $tab) then
          .[$workspace] = {
            current: (.[$workspace].previous // null),
            previous: null
          }
        else
          .
        end
      ' <<<"$state"
    )"
    ;;
  workspace_focused)
    updated="$(
      jq -c --arg workspace "$workspace_id" '
        if ((._workspace.current // "") == $workspace) then
          .
        else
          ._workspace = {
            current: $workspace,
            previous: (._workspace.current // null)
          }
        end
      ' <<<"$state"
    )"
    ;;
  workspace_closed)
    updated="$(
      jq -c --arg workspace "$workspace_id" '
        del(.[$workspace])
        | if ((._workspace.previous // "") == $workspace) then
            ._workspace.previous = null
          elif ((._workspace.current // "") == $workspace) then
            ._workspace = {
              current: (._workspace.previous // null),
              previous: null
            }
          else
            .
          end
      ' <<<"$state"
    )"
    ;;
  *) exit 0 ;;
esac

tmp="$(mktemp "$state_dir/tabs.json.XXXXXX")"
printf '%s\n' "$updated" >"$tmp"
mv "$tmp" "$state_file"
