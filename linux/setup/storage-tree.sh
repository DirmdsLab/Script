#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <external|internal> <path>"
    exit 1
fi

TYPE="$1"
BASE_PATH="$2"

case "$TYPE" in
    external)
        ROOT="$BASE_PATH/Main"
        ;;
    internal)
        ROOT="$BASE_PATH"
        mkdir -p "$ROOT/.config"
        ;;
    *)
        echo "Usage: $0 <external|internal> <path>"
        exit 1
        ;;
esac

echo "Creating folder structure in: $ROOT"

mkdir -p \
    "$ROOT/Documents" \
    "$ROOT/Downloads" \
    "$ROOT/File/Code" \
    "$ROOT/File/Software/App" \
    "$ROOT/File/Software/Game" \
    "$ROOT/File/Software/Storage" \
    "$ROOT/File/Temp" \
    "$ROOT/Pictures/Screenshot" \
    "$ROOT/Pictures/Wallpapers" \
    "$ROOT/Playlists" \
    "$ROOT/Videos/Records" \
    "$ROOT/Videos/Wallpapers"

echo "Folder structure created successfully."