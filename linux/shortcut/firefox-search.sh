#!/usr/bin/env bash

mode=$(printf "new tab\nprivate" | wofi --dmenu --prompt "Mode:")
[ -z "$mode" ] && exit

query=$(wofi --dmenu --prompt "Search or URL:")
[ -z "$query" ] && exit

# build URL
if [[ "$query" =~ ^https?:// ]]; then
    url="$query"
elif [[ "$query" =~ \. ]]; then
    url="https://$query"
else
    url="https://www.google.com/search?q=$(printf '%s' "$query" | jq -s -R -r @uri)"
fi

# PRIVATE MODE
if [[ "$mode" == "private" ]]; then
    firefox --private-window "$url"
    exit
fi

# NEW TAB MODE
if pgrep -x firefox > /dev/null; then
    firefox --new-tab "$url"
else
    firefox "$url"
fi