#!/usr/bin/env bash

# ==========================================
# Generate GitHub SSH Key
#
# Usage:
#   ./sshkey.sh <name>
# ==========================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define paths
LOG_FILE="$SCRIPT_DIR/sshkey.log"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

# Check argument
if [ -z "$1" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi

NAME="$1"

KEY_NAME="id_ed25519_github_${NAME}"
KEY_PATH="$SSH_DIR/$KEY_NAME"

# Create SSH directory if not exists
mkdir -p "$SSH_DIR"

# Generate SSH key
echo "Generating SSH key..."

ssh-keygen \
    -t ed25519 \
    -C "$NAME" \
    -f "$KEY_PATH"

# Ensure SSH config exists
touch "$SSH_CONFIG"

# Add GitHub SSH config
cat >> "$SSH_CONFIG" <<EOF

Host github-$NAME
  HostName github.com
  User git
  IdentityFile ~/.ssh/$KEY_NAME
EOF

# Save log
echo "$(date '+%Y-%m-%d %H:%M:%S') | generated key: $KEY_PATH | host: github-$NAME" >> "$LOG_FILE"

# Output result
echo
echo "SSH key generated successfully"
echo "--------------------------------"
echo "Private key : $KEY_PATH"
echo "Public key  : ${KEY_PATH}.pub"
echo "SSH host    : github-$NAME"
echo "Config file : $SSH_CONFIG"
echo "Log file    : $LOG_FILE"