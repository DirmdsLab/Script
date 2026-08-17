#!/usr/bin/env bash

if hyprctl workspaces | grep "(special:sysmon)" >/dev/null; then
    hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("sysmon"))'
else
    hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("sysmon"))'
    hyprctl eval 'hl.dispatch(hl.dsp.exec_cmd("kitty --class btop-sysmon -T btop fish -c '\''exec btop'\''"))'
fi