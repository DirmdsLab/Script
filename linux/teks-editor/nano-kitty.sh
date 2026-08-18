#!/usr/bin/env bash

file="$1"

# ambil absolute path supaya aman
path="$(realpath "$file")"

# buka kitty + nano
kitty -e nano "$path"
