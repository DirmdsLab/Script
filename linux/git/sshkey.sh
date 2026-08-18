#!/usr/bin/env bash

# ambil direktori script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/sshkey.log"
SSH_CONFIG="$HOME/.ssh/config"

# cek argumen
if [ -z "$1" ]; then
  echo "Usage: $0 <name>"
  exit 1
fi

NAME="$1"
KEY_PATH="$HOME/.ssh/id_ed25519_github_$NAME"

# generate ssh key
ssh-keygen -t ed25519 -C "$NAME" -f "$KEY_PATH"

# pastikan file config ada
touch "$SSH_CONFIG"

# tambah config ke bawah
{
  echo ""
  echo "Host github-$NAME"
  echo "  HostName github.com"
  echo "  User git"
  echo "  IdentityFile ~/.ssh/id_ed25519_github_$NAME"
} >> "$SSH_CONFIG"

# simpan log
echo "$(date '+%Y-%m-%d %H:%M:%S') | generated key: $KEY_PATH | host: github-$NAME" >> "$LOG_FILE"

echo "SSH key generated:"
echo "Private key: $KEY_PATH"
echo "Public key : ${KEY_PATH}.pub"
echo "Config added: github-$NAME"
echo "Log saved to: $LOG_FILE"