#!/usr/bin/env bash

FILE="$1"

# Resolve the absolute file path
FILE_PATH="$(realpath "$FILE")"

# Open the file in Nano using Kitty
kitty -e nano "$FILE_PATH"