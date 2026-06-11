#!/usr/bin/env bash
# Low-battery notifier. Polls every 60s and sends a dunst notification when the
# battery crosses a threshold while discharging. Uses a state file so each
# threshold only notifies once per discharge cycle. Started via exec-once.

BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[ -z "$BAT" ] && exit 0
STATE=/tmp/battery-notify.state

notify() { notify-send -a battery "$@"; }

last=""
while true; do
    cap=$(cat "$BAT/capacity" 2>/dev/null)
    status=$(cat "$BAT/status" 2>/dev/null)
    [ -r "$STATE" ] && last=$(cat "$STATE")

    if [ "$status" = "Discharging" ]; then
        if   [ "$cap" -le 10 ] && [ "$last" != "crit" ]; then
            notify -u critical "Battery critically low" "${cap}% remaining — plug in now"
            echo crit > "$STATE"
        elif [ "$cap" -le 20 ] && [ "$last" != "crit" ] && [ "$last" != "low" ]; then
            notify -u normal "Battery low" "${cap}% remaining"
            echo low > "$STATE"
        fi
    else
        # charging/full — clear so thresholds can fire again next discharge
        [ -n "$last" ] && : > "$STATE"
    fi
    sleep 60
done
