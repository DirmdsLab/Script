#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-normal}"

if (( $# > 1 )) || [[ "$MODE" != "normal" && "$MODE" != "detail" ]]; then
    printf 'Usage: %s [detail]\n' "${0##*/}" >&2
    exit 1
fi

error() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

for command in efibootmgr lsblk jq sort; do
    command -v "$command" >/dev/null 2>&1 || error "Required command not found: $command"
done

[[ -d /sys/firmware/efi/efivars ]] || error 'UEFI variables are not available.'

if ! block_data=$(lsblk --json --list --output PARTN,PARTUUID); then
    error 'Failed to read block devices.'
fi

if ! partition_data=$(jq -r '
    .blockdevices[]
    | select(.partn != null and .partuuid != null)
    | [(.partuuid | ascii_downcase), (.partn | tostring)]
    | @tsv
' <<< "$block_data"); then
    error 'Failed to parse partition information.'
fi

declare -A partitions=()
while IFS=$'\t' read -r uuid partition_number; do
    [[ -n "$uuid" ]] || continue
    partitions["$uuid"]="$partition_number"
done <<< "$partition_data"

if ! boot_data=$(efibootmgr --verbose); then
    error 'Failed to read EFI boot entries.'
fi

current_boot=''
next_boot=''
declare -a entries=()

while IFS= read -r line; do
    if [[ "$line" =~ ^BootCurrent:[[:space:]]*([[:xdigit:]]{4}) ]]; then
        current_boot="${BASH_REMATCH[1]^^}"
        continue
    fi

    if [[ "$line" =~ ^BootNext:[[:space:]]*([[:xdigit:]]{4}) ]]; then
        next_boot="${BASH_REMATCH[1]^^}"
        continue
    fi

    [[ "$line" =~ ^Boot([[:xdigit:]]{4})(\*)?[[:space:]]+ ]] || continue

    boot_id="${BASH_REMATCH[1]^^}"
    active_flag="${BASH_REMATCH[2]}"
    description="${line:${#BASH_REMATCH[0]}}"

    # Only list active entries with a local GPT partition.
    [[ -n "$active_flag" ]] || continue
    [[ "$description" =~ HD\(([0-9]+),GPT,([[:xdigit:]-]+), ]] || continue

    efi_partition="${BASH_REMATCH[1]}"
    partuuid="${BASH_REMATCH[2],,}"
    [[ -v 'partitions[$partuuid]' ]] || continue
    [[ "${partitions[$partuuid]}" == "$efi_partition" ]] || continue

    label="${description%%HD(*}"
    label="${label%"${label##*[![:space:]]}"}"
    label="${label//$'\t'/ }"
    [[ -n "$label" ]] || label="Boot $boot_id"

    case "${description,,}" in
        *windows*) priority=1 ;;
        *nixos*) priority=2 ;;
        *cachy*) priority=3 ;;
        *) priority=9 ;;
    esac

    entries+=("$priority"$'\t'"$boot_id"$'\t'"$label"$'\t'"$efi_partition"$'\t'"$partuuid")
done <<< "$boot_data"

(( ${#entries[@]} > 0 )) || error 'No active EFI entries matched local GPT partitions.'

mapfile -t sorted_entries < <(printf '%s\n' "${entries[@]}" | sort -t $'\t' -k1,1n -k2,2)

declare -a boot_ids=()
declare -a boot_labels=()

printf '\nEFI Boot Entries\n\n'
if [[ "$MODE" == 'detail' ]]; then
    printf ' %-3s %-25s %-9s %-6s %-36s %s\n' 'No' 'Boot entry' 'Partition' 'EFI' 'PARTUUID' 'Status'
    printf ' %s\n' '----------------------------------------------------------------------------------------------------'
else
    printf ' %-3s %-25s %-9s %-6s %s\n' 'No' 'Boot entry' 'Partition' 'EFI' 'Status'
    printf ' %s\n' '----------------------------------------------------------------'
fi

for entry in "${sorted_entries[@]}"; do
    IFS=$'\t' read -r _ boot_id label partition_number partuuid <<< "$entry"
    boot_ids+=("$boot_id")
    boot_labels+=("$label")
    number="${#boot_ids[@]}"

    status='-'
    [[ "$boot_id" == "$current_boot" ]] && status='Current'
    if [[ "$boot_id" == "$next_boot" ]]; then
        if [[ "$status" == 'Current' ]]; then
            status='Current, Next'
        else
            status='Next'
        fi
    fi

    if [[ "$MODE" == 'detail' ]]; then
        printf ' %-3s %-25.25s %-9s %-6s %-36s %s\n' \
            "$number" "$label" "$partition_number" "$boot_id" "$partuuid" "$status"
    else
        printf ' %-3s %-25.25s %-9s %-6s %s\n' \
            "$number" "$label" "$partition_number" "$boot_id" "$status"
    fi
done

printf '\n'
[[ -t 0 ]] || exit 0

read -r -p 'Select boot number (Enter to cancel): ' selection || exit 0
[[ -n "$selection" ]] || exit 0

if [[ ! "$selection" =~ ^[1-9][0-9]*$ ]] || (( ${#selection} > 5 )); then
    error 'Invalid selection.'
fi

index=$((10#$selection - 1))
(( index < ${#boot_ids[@]} )) || error 'Selection is out of range.'

selected_boot="${boot_ids[$index]}"
selected_label="${boot_labels[$index]}"

if (( EUID == 0 )); then
    efibootmgr --bootnext "$selected_boot" >/dev/null || error 'Failed to set the next boot entry.'
else
    command -v sudo >/dev/null 2>&1 || error 'sudo is required to update EFI variables.'
    sudo efibootmgr --bootnext "$selected_boot" >/dev/null || error 'Failed to set the next boot entry.'
fi

printf 'Next boot: %s (Boot%s)\n' "$selected_label" "$selected_boot"
printf 'The system will not reboot automatically.\n'
