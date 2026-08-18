#!/usr/bin/env bash

# Keycode mapping (Linux input system)
declare -A keycodes=(
    [a]=30 [b]=48 [c]=46 [d]=32 [e]=18 [f]=33 [g]=34 [h]=35
    [i]=23 [j]=36 [k]=37 [l]=38 [m]=50 [n]=49 [o]=24 [p]=25
    [q]=16 [r]=19 [s]=31 [t]=20 [u]=22 [v]=47 [w]=17 [x]=45
    [y]=21 [z]=44
    [0]=11 [1]=2 [2]=3 [3]=4 [4]=5 [5]=6 [6]=7 [7]=8 [8]=9 [9]=10
    [enter]=28
    [tab]=15
    [backspace]=14
    [up]=103
    [down]=108
    [left]=105
    [right]=106
)

# Modifier keycodes
SUPER=125
CTRL=29
ALT=56
SHIFT=42

# Helper function: press and release key
press_key() {
    echo -n "$1:1 $1:0 "
}

input="$1"
IFS='+' read -ra keys <<< "$input"

modifiers=()
main_key=""
add_enter=false
add_shift=false
add_tab=false
add_backspace=false
add_up=false
add_down=false
add_left=false
add_right=false

for key in "${keys[@]}"; do
    case "$key" in
        super) modifiers+=($SUPER) ;;
        ctrl)  modifiers+=($CTRL) ;;
        alt)   modifiers+=($ALT) ;;
        shift)
            if [[ -z "$main_key" ]]; then
                modifiers+=($SHIFT)
            else
                add_shift=true
            fi
            ;;
        enter)
            if [[ -z "$main_key" ]]; then
                main_key="enter"
            else
                add_enter=true
            fi
            ;;
        tab)
            if [[ -z "$main_key" ]]; then
                main_key="tab"
            else
                add_tab=true
            fi
            ;;
        backspace)
            if [[ -z "$main_key" ]]; then
                main_key="backspace"
            else
                add_backspace=true
            fi
            ;;
        up)
            if [[ -z "$main_key" ]]; then
                main_key="up"
            else
                add_up=true
            fi
            ;;
        down)
            if [[ -z "$main_key" ]]; then
                main_key="down"
            else
                add_down=true
            fi
            ;;
        left)
            if [[ -z "$main_key" ]]; then
                main_key="left"
            else
                add_left=true
            fi
            ;;
        right)
            if [[ -z "$main_key" ]]; then
                main_key="right"
            else
                add_right=true
            fi
            ;;
        *)
            if [[ -n "$main_key" ]]; then
                echo "Hanya satu tombol utama (huruf/angka) yang didukung."
                exit 1
            fi
            main_key="$key"
            ;;
    esac
done

if [[ -z "$main_key" ]]; then
    echo "Tidak ada tombol utama yang diberikan."
    exit 1
fi

if [[ -v keycodes[$main_key] ]]; then
    keycode=${keycodes[$main_key]}
else
    echo "Key '$main_key' tidak dikenali atau tidak didukung."
    exit 1
fi

cmd=""

# Tekan semua modifiers
for mod in "${modifiers[@]}"; do
    cmd+="$mod:1 "
done

# Tekan & lepas tombol utama
cmd+="$(press_key $keycode)"

# Lepas modifiers dalam urutan terbalik
for (( idx=${#modifiers[@]}-1 ; idx>=0 ; idx-- )); do
    cmd+="${modifiers[$idx]}:0 "
done

# Tambahkan tombol opsional jika ada
[[ $add_enter == true ]] && cmd+="28:1 28:0 "
[[ $add_tab == true ]] && cmd+="15:1 15:0 "
[[ $add_backspace == true ]] && cmd+="14:1 14:0 "
[[ $add_shift == true ]] && cmd+="42:1 42:0 "
[[ $add_up == true ]] && cmd+="103:1 103:0 "
[[ $add_down == true ]] && cmd+="108:1 108:0 "
[[ $add_left == true ]] && cmd+="105:1 105:0 "
[[ $add_right == true ]] && cmd+="106:1 106:0 "

echo "[ydotool] Menjalankan: ydotool key $cmd"

ydotool key $cmd
