#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$SCRIPT_DIR/archive.sh"

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <archive>"
    exit 1
fi

ARCHIVE="$(realpath "$1")"

kitty sh -c '

backend="$1"
archive="$2"

pause() {
    echo
    read -rp "Press Enter to continue (Q to quit): " ans

    case "${ans,,}" in
        q|quit)
            exit 0
            ;;
    esac
}

while true
do

    clear

    echo "=================================================="
    echo " Archive"
    echo "=================================================="
    echo
    echo "$archive"
    echo

    "$backend" list-number "$archive"

    echo
    echo "=================================================="
    echo "Commands"
    echo
    echo "  a           Extract All"
    echo "  t           Test Archive"
    echo "  q           Quit"
    echo
    echo "Or type file numbers: (1, 2-4, 1 3 5, 1 3 7-10)"
    echo "=================================================="
    echo

    read -rp "> " input

    [[ -z "$input" ]] && continue

    case "${input,,}" in

        a)

            echo
            "$backend" extract "$archive"

            pause
            ;;

        t)

            echo
            "$backend" test "$archive"

            pause
            ;;

        q|quit|exit)

            exit 0
            ;;

        *)

            echo

            # Semua input selain command dianggap nomor file
            # shellcheck disable=SC2086
            if "$backend" extract-file "$archive" $input
            then
                pause
            else
                echo
                echo "Invalid selection."
                pause
            fi
            ;;

    esac

done

' sh "$BACKEND" "$ARCHIVE"