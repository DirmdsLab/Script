#!/usr/bin/env bash

set -euo pipefail

# Built-in Linux evdev keycodes for standard, extended, and media keyboards.
declare -A keycodes=(
    [esc]=1 [1]=2 [2]=3 [3]=4 [4]=5 [5]=6 [6]=7 [7]=8 [8]=9 [9]=10 [0]=11
    [minus]=12 [equal]=13 [backspace]=14 [tab]=15
    [q]=16 [w]=17 [e]=18 [r]=19 [t]=20 [y]=21 [u]=22 [i]=23 [o]=24 [p]=25
    [leftbrace]=26 [rightbrace]=27 [enter]=28 [leftctrl]=29
    [a]=30 [s]=31 [d]=32 [f]=33 [g]=34 [h]=35 [j]=36 [k]=37 [l]=38
    [semicolon]=39 [apostrophe]=40 [grave]=41 [leftshift]=42 [backslash]=43
    [z]=44 [x]=45 [c]=46 [v]=47 [b]=48 [n]=49 [m]=50
    [comma]=51 [dot]=52 [slash]=53 [rightshift]=54 [kpasterisk]=55
    [leftalt]=56 [space]=57 [capslock]=58
    [f1]=59 [f2]=60 [f3]=61 [f4]=62 [f5]=63 [f6]=64
    [f7]=65 [f8]=66 [f9]=67 [f10]=68 [numlock]=69 [scrolllock]=70
    [kp7]=71 [kp8]=72 [kp9]=73 [kpminus]=74 [kp4]=75 [kp5]=76
    [kp6]=77 [kpplus]=78 [kp1]=79 [kp2]=80 [kp3]=81 [kp0]=82 [kpdot]=83
    [zenkakuhankaku]=85 [102nd]=86 [f11]=87 [f12]=88
    [ro]=89 [katakana]=90 [hiragana]=91 [henkan]=92
    [katakanahiragana]=93 [muhenkan]=94 [kpjpcomma]=95 [kpenter]=96
    [rightctrl]=97 [kpslash]=98 [sysrq]=99 [rightalt]=100 [linefeed]=101
    [home]=102 [up]=103 [pageup]=104 [left]=105 [right]=106
    [end]=107 [down]=108 [pagedown]=109 [insert]=110 [delete]=111
    [macro]=112 [mute]=113 [volumedown]=114 [volumeup]=115 [power]=116
    [kpequal]=117 [kpplusminus]=118 [pause]=119 [scale]=120 [kpcomma]=121
    [hangeul]=122 [hanja]=123 [yen]=124 [leftmeta]=125 [rightmeta]=126
    [compose]=127 [stop]=128 [again]=129 [props]=130 [undo]=131
    [front]=132 [copy]=133 [open]=134 [paste]=135 [find]=136 [cut]=137
    [help]=138 [menu]=139 [calc]=140 [setup]=141 [sleep]=142 [wakeup]=143
    [file]=144 [sendfile]=145 [deletefile]=146 [xfer]=147
    [prog1]=148 [prog2]=149 [www]=150 [msdos]=151 [coffee]=152
    [rotate_display]=153 [cyclewindows]=154 [mail]=155 [bookmarks]=156
    [computer]=157 [back]=158 [forward]=159 [closecd]=160
    [ejectcd]=161 [ejectclosecd]=162 [nextsong]=163 [playpause]=164
    [previoussong]=165 [stopcd]=166 [record]=167 [rewind]=168
    [phone]=169 [iso]=170 [config]=171 [homepage]=172 [refresh]=173
    [exit]=174 [move]=175 [edit]=176 [scrollup]=177 [scrolldown]=178
    [kpleftparen]=179 [kprightparen]=180 [new]=181 [redo]=182
    [f13]=183 [f14]=184 [f15]=185 [f16]=186 [f17]=187 [f18]=188
    [f19]=189 [f20]=190 [f21]=191 [f22]=192 [f23]=193 [f24]=194
    [playcd]=200 [pausecd]=201 [prog3]=202 [prog4]=203
    [all_applications]=204 [suspend]=205 [close]=206 [play]=207
    [fastforward]=208 [bassboost]=209 [print]=210 [hp]=211
    [camera]=212 [sound]=213 [question]=214 [email]=215 [chat]=216
    [search]=217 [connect]=218 [finance]=219 [sport]=220 [shop]=221
    [alterase]=222 [cancel]=223 [brightnessdown]=224 [brightnessup]=225
    [media]=226 [switchvideomode]=227 [kbdillumtoggle]=228
    [kbdillumdown]=229 [kbdillumup]=230 [send]=231 [reply]=232
    [forwardmail]=233 [save]=234 [documents]=235 [battery]=236
    [bluetooth]=237 [wlan]=238 [uwb]=239 [unknown]=240
    [video_next]=241 [video_prev]=242 [brightness_cycle]=243
    [brightness_auto]=244 [display_off]=245 [wwan]=246
    [rfkill]=247 [micmute]=248
    [fn]=464 [fn_esc]=465 [fn_f1]=466 [fn_f2]=467 [fn_f3]=468
    [fn_f4]=469 [fn_f5]=470 [fn_f6]=471 [fn_f7]=472 [fn_f8]=473
    [fn_f9]=474 [fn_f10]=475 [fn_f11]=476 [fn_f12]=477
    [fn_1]=478 [fn_2]=479 [fn_d]=480 [fn_e]=481 [fn_f]=482
    [fn_s]=483 [fn_b]=484 [fn_right_shift]=485
    [touchpad_toggle]=530 [touchpad_on]=531 [touchpad_off]=532
    [camera_zoomin]=533 [camera_zoomout]=534
    [als_toggle]=560 [rotate_lock_toggle]=561 [refresh_rate_toggle]=562
    [buttonconfig]=576 [taskmanager]=577 [journal]=578
    [controlpanel]=579 [appselect]=580 [screensaver]=581
    [voicecommand]=582 [assistant]=583 [kbd_layout_next]=584
    [emoji_picker]=585 [dictate]=586
)

# Populate additional keys from the installed kernel header when available.
load_kernel_keycodes() {
    local header directive name value rest key_name

    for header in \
        /usr/include/linux/input-event-codes.h \
        /run/current-system/sw/include/linux/input-event-codes.h; do
        [[ -r "$header" ]] || continue

        while read -r directive name value rest; do
            [[ "$directive" == '#define' && "$name" == KEY_* ]] || continue
            [[ "$value" =~ ^(0[xX][0-9a-fA-F]+|[0-9]+)$ ]] || continue

            key_name="${name#KEY_}"
            keycodes["${key_name,,}"]=$((value))
        done < "$header"

        break
    done
}

# Normalize aliases without changing Linux keycode meanings.
normalize_key() {
    local name="${1,,}"
    name="${name//-/_}"
    name="${name#key_}"

    case "$name" in
        super|win|windows|meta|command|cmd|lwin) name=leftmeta ;;
        rwin|rmeta) name=rightmeta ;;
        ctrl|control|lctrl|leftcontrol) name=leftctrl ;;
        rctrl|rightcontrol) name=rightctrl ;;
        alt|lalt|option) name=leftalt ;;
        ralt|altgr) name=rightalt ;;
        shift|lshift) name=leftshift ;;
        rshift) name=rightshift ;;
        escape) name=esc ;;
        return) name=enter ;;
        spacebar) name=space ;;
        del) name=delete ;;
        ins) name=insert ;;
        pgup|page_up) name=pageup ;;
        pgdn|page_down) name=pagedown ;;
        printscreen|prtsc|prtscr) name=sysrq ;;
        period) name=dot ;;
        quote) name=apostrophe ;;
        backtick|tilde_key) name=grave ;;
        leftbracket|lbracket) name=leftbrace ;;
        rightbracket|rbracket) name=rightbrace ;;
        volume_up) name=volumeup ;;
        volume_down) name=volumedown ;;
        volume_mute) name=mute ;;
        play_pause) name=playpause ;;
        next_track) name=nextsong ;;
        previous_track|prev_track) name=previoussong ;;
        numpad_enter) name=kpenter ;;
        numpad_add) name=kpplus ;;
        numpad_subtract) name=kpminus ;;
        numpad_multiply) name=kpasterisk ;;
        numpad_divide) name=kpslash ;;
        numpad_decimal) name=kpdot ;;
        numpad[0-9]) name="kp${name#numpad}" ;;
    esac

    printf '%s\n' "$name"
}

is_modifier() {
    case "$1" in
        leftctrl|rightctrl|leftalt|rightalt|leftshift|rightshift|leftmeta|rightmeta)
            return 0 ;;
        *) return 1 ;;
    esac
}

show_usage() {
    cat <<'USAGE'
Usage:
  keyboard-ydotool.sh 'ctrl+alt+delete'
  keyboard-ydotool.sh 'super+shift+s'
  keyboard-ydotool.sh 'a+enter+tab'
  keyboard-ydotool.sh 'f24'
  keyboard-ydotool.sh 'key_brightnessup'
  keyboard-ydotool.sh 'code:706'
  keyboard-ydotool.sh --dry-run 'ctrl+alt+f4'
  keyboard-ydotool.sh --list

Rules:
  + separates keys.
  Modifiers before the first regular key form a shortcut.
  Keys after the first regular key are pressed separately in order.
  Named keys use Linux KEY_* names without the KEY_ prefix.
  code:N accepts a numeric Linux evdev keycode (1-767).
USAGE
}

load_kernel_keycodes

case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    --list)
        printf '%s\n' "${!keycodes[@]}" | LC_ALL=C sort
        exit 0
        ;;
esac

dry_run=false

if [[ "${1:-}" == --dry-run ]]; then
    dry_run=true
    shift
fi

if (( $# != 1 )) || [[ -z "$1" ]]; then
    show_usage >&2
    exit 1
fi

input="$1"

if [[ "$input" == +* || "$input" == *+ || "$input" == *++* ]]; then
    printf 'Error: Invalid key combination: %s\n' "$input" >&2
    exit 1
fi

IFS='+' read -r -a tokens <<< "$input"

declare -a events=() pressed_modifiers=()
main_key_pressed=false

for token in "${tokens[@]}"; do
    token="${token//[[:space:]]/}"

    [[ -n "$token" ]] || {
        printf 'Error: Empty key name.\n' >&2
        exit 1
    }

    if [[ "$token" =~ ^[cC][oO][dD][eE]:([0-9]{1,4})$ ]]; then
        keycode=$((10#${BASH_REMATCH[1]}))

        if (( keycode < 1 || keycode > 767 )); then
            printf 'Error: Keycode out of range: %s\n' "$token" >&2
            exit 1
        fi

        name=""
    else
        name="$(normalize_key "$token")"

        if [[ ! "$name" =~ ^[a-z0-9_]+$ ]] || [[ ! -v keycodes["$name"] ]]; then
            printf 'Error: Unknown key: %s\n' "$token" >&2
            exit 1
        fi

        keycode="${keycodes[$name]}"
    fi

    if [[ "$main_key_pressed" == false ]] && is_modifier "$name"; then
        # Avoid pressing the same modifier twice before the shortcut key.
        already_pressed=false

        for held_keycode in "${pressed_modifiers[@]}"; do
            if [[ "$held_keycode" == "$keycode" ]]; then
                already_pressed=true
                break
            fi
        done

        if [[ "$already_pressed" == false ]]; then
            events+=("$keycode:1")
            pressed_modifiers+=("$keycode")
        fi

        continue
    fi

    events+=("$keycode:1" "$keycode:0")

    if [[ "$main_key_pressed" == false ]]; then
        for (( i=${#pressed_modifiers[@]}-1; i>=0; i-- )); do
            events+=("${pressed_modifiers[i]}:0")
        done

        main_key_pressed=true
    fi
done

# A modifier-only input is also a valid key combination.
if [[ "$main_key_pressed" == false ]]; then
    for (( i=${#pressed_modifiers[@]}-1; i>=0; i-- )); do
        events+=("${pressed_modifiers[i]}:0")
    done
fi

printf '[ydotool] ydotool key'
printf ' %s' "${events[@]}"
printf '\n'

if [[ "$dry_run" == true ]]; then
    exit 0
fi

if ! command -v ydotool >/dev/null 2>&1; then
    printf 'Error: ydotool is not installed or not in PATH.\n' >&2
    exit 1
fi

ydotool key "${events[@]}"
