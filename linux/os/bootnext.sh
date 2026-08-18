#!/usr/bin/env bash

echo "Daftar EFI Boot Entry (NVRAM)"
echo "=============================="
echo

efibootmgr | grep '^Boot[0-9A-F]\{4\}' | while read -r line; do
    bootnum=$(echo "$line" | cut -c1-8)
    desc=$(echo "$line" | sed 's/^Boot[0-9A-F]\{4\}\* //')

    echo "Boot Number : $bootnum"
    echo "Description : $desc"
    echo
done
