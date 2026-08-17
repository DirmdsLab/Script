#!/usr/bin/env bash
gateway_ip=$(ip route | awk '/default/ {print $3}')
pactl load-module module-tunnel-sink server="$gateway_ip"

# 2nd Run