#!/usr/bin/env bash
set -euo pipefail

# Equalize split ratios in a herdr tab, like tmux's select-layout -E.
#
# Usage: balance.sh [right|down|all]
#   right — equalize columns (vertical splits) only
#   down  — equalize rows (horizontal splits) only
#
# The herdr CLI does not expose layout.export / layout.set_split_ratio, so
# this speaks newline-delimited JSON to the server socket directly. Herdr
# closes the connection after each response, which lets plain nc work.
#
# Splits are stored as a nested binary tree, so "N equal columns" is not N
# ratios of 1/N: each split's ratio must be (leaf cells in its first subtree)
# divided by (leaf cells along its direction). A perpendicular split counts
# as a single cell.

only="${1:-all}"
case "$only" in
  right | down | all) ;;
  *)
    echo "usage: balance.sh [right|down|all]" >&2
    exit 2
    ;;
esac

sock="${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}"

rpc() {
  local method="$1" params="$2"
  jq -cn --arg method "$method" --argjson params "$params" \
    '{id: "balance-splits", method: $method, params: $params}' \
    | nc -U "$sock"
}

# When invoked by a pane event, balance the tab the event happened in.
# Otherwise (action binding, CLI) fall back to this pane's tab, then to
# whichever tab is focused.
tab_id=""
if [[ -n "${HERDR_PLUGIN_EVENT_JSON:-}" ]]; then
  event="$HERDR_PLUGIN_EVENT_JSON"
  # Herdr 0.7.5 can inject this through more than one JSON-string layer.
  for _ in {1..4}; do
    [[ "$(jq -r 'type' <<<"$event")" == string ]] || break
    event="$(jq -r 'fromjson' <<<"$event")"
  done
  tab_id="$(jq -r '(.data // .) | .tab_id // empty' <<<"$event")"
fi
[[ -n "$tab_id" ]] || tab_id="${HERDR_TAB_ID:-}"

if [[ -n "$tab_id" ]]; then
  params="$(jq -cn --arg tab "$tab_id" '{tab_id: $tab}')"
else
  params='{}'
fi

exported="$(rpc layout.export "$params")"
if [[ -z "$exported" ]] || jq -e '.error' <<<"$exported" >/dev/null; then
  echo "balance-splits: layout.export failed: ${exported:-no response}" >&2
  exit 1
fi
tab_id="$(jq -r '.result.layout.tab_id' <<<"$exported")"

# Emit one {path, ratio} line per split whose ratio needs to change. The
# path is the boolean first/second trail layout.set_split_ratio expects.
plan="$(jq -c --arg only "$only" '
  def cells($d):
    if .type == "split" and .direction == $d
    then (.first | cells($d)) + (.second | cells($d))
    else 1 end;
  def plan:
    if .type != "split" then [] else
      . as $n
      | ($n.first | cells($n.direction)) as $a
      | ($n.second | cells($n.direction)) as $b
      | (if ($only == "all" or $only == $n.direction)
            and ((($n.ratio - ($a / ($a + $b))) | fabs) > 0.001)
         then [{path: [], ratio: ($a / ($a + $b))}]
         else [] end)
        + ($n.first | plan | map(.path = [false] + .path))
        + ($n.second | plan | map(.path = [true] + .path))
    end;
  .result.layout.root | plan | .[]
' <<<"$exported")"

# Ratio changes never alter the tree topology, so paths computed from one
# export stay valid across sequential updates.
while IFS= read -r step; do
  [[ -n "$step" ]] || continue
  rpc layout.set_split_ratio \
    "$(jq -c --arg tab "$tab_id" '. + {tab_id: $tab}' <<<"$step")" >/dev/null
done <<<"$plan"
