#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <storage_path>"
    exit 1
fi

BASE="$1"
NAME="$(basename "$BASE")"

# Pastikan folder tujuan ada
mkdir -p "$HOME/Documents"
mkdir -p "$HOME/Downloads"
mkdir -p "$HOME/Pictures"
mkdir -p "$HOME/Videos"
mkdir -p "$HOME/Playlists"

mkdir -p "$HOME/File"
mkdir -p "$HOME/File/Code"
mkdir -p "$HOME/File/Software"
mkdir -p "$HOME/File/Temp"

mkdir -p "$HOME/File/Software/Game"
mkdir -p "$HOME/File/Software/App"

# Main
ln -sfn "$BASE/Main/Documents" "$HOME/Documents/Document-$NAME"
ln -sfn "$BASE/Main/Downloads" "$HOME/Downloads/Download-$NAME"
ln -sfn "$BASE/Main/Pictures"  "$HOME/Pictures/Picture-$NAME"
ln -sfn "$BASE/Main/Videos"    "$HOME/Videos/Video-$NAME"
ln -sfn "$BASE/Main/Playlists" "$HOME/Playlists/Playlist-$NAME"

# File
ln -sfn "$BASE/Main/File/Code"     "$HOME/File/Code/Code-$NAME"
ln -sfn "$BASE/Main/File/Temp"     "$HOME/File/Temp/Temp-$NAME"
ln -sfn "$BASE/Main/File/Software" "$HOME/File/Software/Software-$NAME"

# Software
ln -sfn "$BASE/Main/File/Software/Game"   "$HOME/File/Software/Game/Game-$NAME"
ln -sfn "$BASE/Main/File/Software/App"    "$HOME/File/Software/App/App-$NAME"

echo "Linked storage: $NAME"