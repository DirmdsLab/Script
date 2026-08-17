#!/usr/bin/env bash

# fetch client data (workspace id + class)
clients=$(hyprctl clients -j | jq -r '.[] | "\(.workspace.id) \(.class)"')

# declare counter per workspace
declare -A counters
declare -A entries

ICON="🖥️"   # customize as you like, other example: 🪟

# collect all windows
while read -r ws class; do
    # skip negative workspaces (-98, -99)
    if [[ $ws -lt 0 ]]; then
        continue
    fi

    counters[$ws]=$(( ${counters[$ws]} + 1 ))

    if [[ ${counters[$ws]} -gt 1 ]]; then
        label="${ws}-${counters[$ws]}: ${ICON} ${class}"
    else
        label="${ws}: ${ICON} ${class}"
    fi

    entries["$ws,${counters[$ws]}"]="$label"
done <<< "$clients"

# sort workspaces (numeric)
menu=""
for key in $(printf "%s\n" "${!entries[@]}" | sort -t, -k1,1n -k2,2n); do
    menu+="${entries[$key]}"$'\n'
done

# show in wofi
choice=$(echo -n "$menu" | wofi --dmenu --prompt "Workspace/App")

# extract workspace id from selection
ws=$(echo "$choice" | cut -d: -f1 | cut -d- -f1)

# switch to that workspace
hyprctl dispatch "hl.dsp.focus({ workspace = $ws })"