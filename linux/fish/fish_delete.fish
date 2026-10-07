#!/usr/bin/env fish

# ==========================================
# Delete recent Fish history entries
#
# Usage:
#   ./fish_delete.fish <minutes>
#
# Example:
#   ./fish_delete.fish 10
#   ./fish_delete.fish 20
# ==========================================

function show_usage
    echo "Usage: $argv[1] <minutes>"
    echo ""
    echo "Example:"
    echo "  $argv[1] 10"
    echo "  $argv[1] 20"
end


# Validate arguments
if test (count $argv) -ne 1
    show_usage
    exit 1
end


set minutes $argv[1]


# Validate numeric input
if not string match -qr '^[0-9]+$' -- $minutes
    echo "Error: minutes must be a number."
    exit 1
end


# Locate Fish history file
if set -q XDG_DATA_HOME
    set history_file "$XDG_DATA_HOME/fish/fish_history"
else
    set history_file "$HOME/.local/share/fish/fish_history"
end


# Check history file
if not test -f "$history_file"
    echo "Error: Fish history file not found:"
    echo "$history_file"
    exit 1
end


# Calculate cutoff timestamp
set now (date +%s)
set cutoff (math "$now - ($minutes * 60)")

set now_date (date "+%Y-%m-%d %H:%M:%S")
set cutoff_date (date -d "@$cutoff" "+%Y-%m-%d %H:%M:%S")


echo ""
echo "=========================================="
echo "          FISH HISTORY CLEANER"
echo "=========================================="
echo ""
echo "History file : $history_file"
echo "Current time : $now_date"
echo "Delete since : $cutoff_date"
echo "Time range   : Last $minutes minutes"
echo ""
echo "WARNING:"
echo "All history entries within this range"
echo "will be permanently deleted."
echo ""


read -P "Continue? [y/N] " confirm


switch $confirm
    case y Y yes YES Yes
        echo ""
        echo "Processing history..."
    case '*'
        echo ""
        echo "Cancelled. No changes made."
        exit 0
end


set temp_file (mktemp)
set backup_file "$history_file.backup"


# Create backup
cp "$history_file" "$backup_file"


# Remove recent history entries
awk -v cutoff="$cutoff" '
BEGIN {
    skip = 0
    entry_time = 0
}

/^- cmd:/ {
    if (entry_time >= cutoff) {
        skip = 1
    } else {
        skip = 0
    }

    entry_time = 0
}

/^  when:/ {
    entry_time = $2
}

{
    if (!skip) {
        print
    }
}
' "$history_file" > "$temp_file"


if test $status -ne 0
    echo "Error: failed to process history."
    rm -f "$temp_file"
    exit 1
end


# Replace history file
mv "$temp_file" "$history_file"


if test $status -ne 0
    echo "Error: failed to update history file."
    exit 1
end


# Reload Fish history
history merge


echo ""
echo "=========================================="
echo "Completed successfully."
echo "Deleted history from the last $minutes minutes."
echo "Backup saved:"
echo "$backup_file"
echo "=========================================="