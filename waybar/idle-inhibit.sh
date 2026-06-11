#!/bin/bash
SWAYIDLE_CMD="swayidle -w \
    timeout 150 'brightnessctl -s set 10' resume 'brightnessctl -r' \
    timeout 300 'pidof hyprlock || hyprlock' \
    timeout 360 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' \
    before-sleep 'pidof hyprlock || hyprlock'"

case "$1" in
    toggle)
        if pgrep -x swayidle > /dev/null; then
            pkill swayidle
        else
            eval "$SWAYIDLE_CMD" &
        fi
        ;;
    *)
        if pgrep -x swayidle > /dev/null; then
            echo "lock"
        else
            echo "nolck"
        fi
        ;;
esac
