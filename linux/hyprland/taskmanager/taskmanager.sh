#!/usr/bin/env bash

if hyprctl workspaces | grep -q "(special:sysmon)"; then

    hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("sysmon"))'

else

    hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("sysmon"))'

    hyprctl eval "hl.dispatch(hl.dsp.exec_cmd(\"kitty --class btop-sysmon -T sysmon --session $HOME/.config/kitty/sysmon.session\"))"

fi