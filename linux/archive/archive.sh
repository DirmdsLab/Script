#!/usr/bin/env bash

set -Eeuo pipefail

usage() {
    local cmd
    cmd="$(basename "$0")"

    cat <<EOF
Usage:
  $cmd <archive>
  $cmd {list|list-number|extract|extract-file|test} <archive>

Commands:
  list               List contents (default)
  list-number        List contents with numbers
  extract            Extract all
  extract-file       Extract selected file numbers
  test               Test archive integrity
EOF
}

die() {
    echo "Error: $*" >&2
    exit 1
}

require_file() {
    [[ -f "$1" ]] || die "File not found: $1"
}

archive_name() {
    local name
    name="$(basename "$1")"

    case "$name" in
        *.tar.gz)  echo "${name%.tar.gz}" ;;
        *.tar.bz2) echo "${name%.tar.bz2}" ;;
        *.tar.xz)  echo "${name%.tar.xz}" ;;
        *.tar.zst) echo "${name%.tar.zst}" ;;
        *.tar)     echo "${name%.tar}" ;;
        *.zip)     echo "${name%.zip}" ;;
        *.7z)      echo "${name%.7z}" ;;
        *.rar)     echo "${name%.rar}" ;;
        *.gz)      echo "${name%.gz}" ;;
        *.bz2)     echo "${name%.bz2}" ;;
        *.xz)      echo "${name%.xz}" ;;
        *.zst)     echo "${name%.zst}" ;;
        *)         echo "${name%.*}" ;;
    esac
}

next_output_dir() {

    local archive="$1"

    local parent
    local base
    local dir
    local n=1

    parent="$(dirname "$archive")"
    base="$(archive_name "$archive")"

    dir="$parent/$base"

    while [[ -e "$dir" ]]; do
        dir="$parent/${base}-${n}"
        ((n++))
    done

    mkdir -p "$dir"

    echo "$dir"
}

list_archive() {

    require_file "$1"

    7z l "$1"
}

list_number() {

    require_file "$1"

    local i=1

    7z l -slt "$1" |
    awk -F'= ' '
        /^Path = / {
            print $2
        }
    ' |
    tail -n +2 |
    while read -r path
    do
        printf "%3d. %s\n" "$i" "$path"
        ((i++))
    done
}

get_paths() {

    7z l -slt "$1" |
    awk -F'= ' '
        /^Path = / {
            print $2
        }
    ' |
    tail -n +2
}

extract_archive() {

    require_file "$1"

    local out

    out="$(next_output_dir "$1")"

    echo "Output: $out"

    7z x "$1" "-o$out"
}

extract_file() {

    [[ $# -ge 2 ]] || die "Usage: extract-file <archive> numbers..."

    local archive="$1"

    shift

    require_file "$archive"

    mapfile -t files < <(get_paths "$archive")

    local out

    out="$(next_output_dir "$archive")"

    echo "Output: $out"

    local selections=()

    local token

    for token in "$@"
    do

        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]
        then

            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"

            local i

            for ((i=start;i<=end;i++))
            do
                ((i>=1 && i<=${#files[@]})) || continue
                selections+=("${files[$((i-1))]}")
            done

        elif [[ "$token" =~ ^[0-9]+$ ]]
        then

            local idx="$token"

            ((idx>=1 && idx<=${#files[@]})) || continue

            selections+=("${files[$((idx-1))]}")

        fi

    done

    [[ ${#selections[@]} -gt 0 ]] || die "Nothing selected."

    7z x "$archive" "-o$out" -- "${selections[@]}"
}

test_archive() {

    require_file "$1"

    7z t "$1"
}

case "${1:-}" in

    ""|-h|--help|help)

        usage
        ;;

    list)

        [[ $# -eq 2 ]] || usage

        list_archive "$2"
        ;;

    list-number)

        [[ $# -eq 2 ]] || usage

        list_number "$2"
        ;;

    extract|x)

        [[ $# -eq 2 ]] || usage

        extract_archive "$2"
        ;;

    extract-file|xf)

        [[ $# -ge 3 ]] || usage

        archive="$2"

        shift 2

        extract_file "$archive" "$@"
        ;;

    test|t)

        [[ $# -eq 2 ]] || usage

        test_archive "$2"
        ;;

    *)

        [[ $# -eq 1 ]] || usage

        list_archive "$1"
        ;;

esac