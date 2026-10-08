#!/usr/bin/env bash

set -euo pipefail

# Display an error and exit
fail() {
    printf 'Error: %s\n' "$1" >&2

    if command -v notify-send >/dev/null 2>&1; then
        notify-send 'Hyprland Opacity' "$1" 2>/dev/null || true
    fi

    exit 1
}

# Check required dependencies
for dependency in hyprctl jq wofi; do
    command -v "$dependency" >/dev/null 2>&1 ||
        fail "Missing dependency: $dependency"
done

# Retrieve the active window
if ! active_window=$(hyprctl activewindow -j); then
    fail 'Failed to retrieve the active window.'
fi

# Validate and display window information
if ! window_info=$(jq -er '
    select(type == "object" and (.class | type == "string" and length > 0))
    | "Active window:\nClass: \(.class)\nTitle: \(.title // "")"
' <<< "$active_window"); then
    fail 'No active window found.'
fi

printf '%s\n' "$window_info"

# Select opacity
opacity=$(printf '%s\n' \
    '1' '0.95' '0.9' '0.8' '0.7' '0.5' '0.3' '0.2' '0.1' |
    wofi --dmenu --prompt 'Opacity') || exit 0

[[ -n "$opacity" ]] || exit 0

# Validate the selected opacity
case "$opacity" in
    1|0.95|0.9|0.8|0.7|0.5|0.3|0.2|0.1) ;;
    *) fail "Invalid opacity: $opacity" ;;
esac

# Select the matching scope
target=$(printf '%s\n' 'Class + Title' 'Class Only' |
    wofi --dmenu --prompt 'Target Rule') || exit 0

[[ -n "$target" ]] || exit 0

# Validate the selected target
case "$target" in
    'Class + Title'|'Class Only') ;;
    *) fail "Invalid target: $target" ;;
esac

# Generate a safely escaped Lua window rule
if ! lua_rule=$(jq -er \
    --arg opacity "$opacity" \
    --arg target "$target" '
    def escape_regex:
        explode
        | map(
            . as $code
            | ([$code] | implode) as $character
            | if ([46, 94, 36, 42, 43, 63, 40, 41, 91, 93, 123, 125, 124, 92] | index($code)) != null
              then "\\" + $character
              else $character
              end
        )
        | join("")
        | "^" + . + "$";

    def quote_lua:
        explode
        | map(
            . as $code
            | if $code == 34 then "\\\""
              elif $code == 92 then "\\\\"
              elif $code < 32 or $code == 127 then
                  "\\" + ("00" + ($code | tostring))[-3:]
              else [$code] | implode
              end
        )
        | join("")
        | "\"" + . + "\"";

    (.class | escape_regex | quote_lua) as $class
    | ((.title // "") | escape_regex | quote_lua) as $title
    | (
        if $target == "Class + Title"
        then "class = \($class), title = \($title)"
        else "class = \($class)"
        end
    ) as $match
    | "hl.window_rule({ match = { \($match) }, opacity = \"\($opacity) override \($opacity) override \($opacity) override\" })"
' <<< "$active_window"); then
    fail 'Failed to generate the window rule.'
fi

# Display the generated rule
printf 'Applying rule:\n%s\n' "$lua_rule"

# Apply the rule dynamically
if ! hyprctl eval "$lua_rule"; then
    fail 'Failed to apply the window rule.'
fi