#!/usr/bin/env bash

set -euo pipefail

# Check required dependencies
for dependency in hyprctl jq wofi; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Missing dependency: %s\n' "$dependency" >&2
        exit 1
    fi
done

# Fetch all Hyprland clients
if ! clients_json=$(hyprctl clients -j); then
    printf 'Failed to retrieve Hyprland clients.\n' >&2
    exit 1
fi

# Collect windows from regular, named, and special workspaces
if ! clients_tsv=$(jq -r '
    [
        .[]
        | select((.workspace.name // "") != "")
        | {
            workspace_id: .workspace.id,
            workspace_name: .workspace.name,
            address: .address,
            class: (
                (.class // "Unknown")
                | gsub("[\r\n\t]"; " ")
                | if . == "" then "Unknown" else . end
            ),
            title: (
                (.title // "")
                | gsub("[\r\n\t]"; " ")
            )
        }
    ]
    | sort_by([
        (
            if (
                .workspace_name == "special"
                or (.workspace_name | startswith("special:"))
            ) then 2
            elif .workspace_id > 0 then 0
            else 1
            end
        ),
        (
            if .workspace_id > 0
            then .workspace_id
            else 0
            end
        ),
        .workspace_name,
        .class,
        .title
    ])
    | .[]
    | [
        .workspace_name,
        .address,
        .class,
        .title
    ]
    | @tsv
' <<< "$clients_json"); then
    printf 'Failed to parse Hyprland clients.\n' >&2
    exit 1
fi

# Exit when no windows are available
if [[ -z "$clients_tsv" ]]; then
    printf 'No windows available.\n'
    exit 0
fi

# Build the Wofi menu
declare -a menu_entries=()
declare -a window_addresses=()
declare -a workspace_names=()

entry_number=0

while IFS=$'\t' read -r workspace_name address window_class window_title; do
    # Skip invalid window addresses
    [[ "$address" =~ ^0x[[:xdigit:]]+$ ]] || continue

    ((entry_number += 1))

    # Identify workspace type
    if [[ "$workspace_name" == "special" ]]; then
        workspace_label="SPECIAL default"
    elif [[ "$workspace_name" == special:* ]]; then
        workspace_label="SPECIAL ${workspace_name#special:}"
    else
        workspace_label="WS ${workspace_name}"
    fi

    # Generate menu entry
    printf -v entry \
        '%02d  [%s] %s' \
        "$entry_number" \
        "$workspace_label" \
        "$window_class"

    if [[ -n "$window_title" ]]; then
        entry+=" - ${window_title:0:80}"
    fi

    menu_entries+=("$entry")
    window_addresses+=("$address")
    workspace_names+=("$workspace_name")
done <<< "$clients_tsv"

if ((entry_number == 0)); then
    printf 'No valid windows available.\n'
    exit 0
fi

# Show the window selection menu
selection=$(
    printf '%s\n' "${menu_entries[@]}" |
        wofi \
            --dmenu \
            --prompt "Switch Window" \
            --hide-scroll
) || exit 0

[[ -n "$selection" ]] || exit 0

# Resolve the selected window
selected_address=""
selected_workspace=""

for index in "${!menu_entries[@]}"; do
    if [[ "${menu_entries[$index]}" == "$selection" ]]; then
        selected_address="${window_addresses[$index]}"
        selected_workspace="${workspace_names[$index]}"
        break
    fi
done

[[ -n "$selected_address" ]] || exit 0

# Handle special workspaces
if [[ "$selected_workspace" == "special" ||
      "$selected_workspace" == special:* ]]; then

    # Check currently visible special workspaces
    if ! monitors_json=$(hyprctl monitors -j); then
        printf 'Failed to retrieve Hyprland monitors.\n' >&2
        exit 1
    fi

    if ! special_visible=$(jq -r \
        --arg workspace "$selected_workspace" '
        any(
            .[];
            (.specialWorkspace.name // "") == $workspace
        )
    ' <<< "$monitors_json"); then
        printf 'Failed to inspect special workspaces.\n' >&2
        exit 1
    fi

    # Only open the special workspace when hidden
    if [[ "$special_visible" != "true" ]]; then

        if [[ "$selected_workspace" == "special" ]]; then
            toggle_command='hl.dsp.workspace.toggle_special()'
        else
            special_name="${selected_workspace#special:}"

            # Escape the workspace name for the Lua dispatcher
            quoted_name=$(jq -rn \
                --arg value "$special_name" \
                '$value | @json')

            toggle_command="hl.dsp.workspace.toggle_special(${quoted_name})"
        fi

        hyprctl dispatch "$toggle_command" >/dev/null
    fi
fi

# Focus the selected window by its unique address
hyprctl dispatch \
    "hl.dsp.focus({ window = \"address:${selected_address}\" })" \
    >/dev/null