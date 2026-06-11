#!/bin/bash

# Get bluetooth power state
BT_POWERED=$(bluetoothctl show | grep -i "powered:" | awk '{print $2}')

if [ "$BT_POWERED" = "no" ]; then
    CHOICE=$(printf "Turn On" | wofi --dmenu --prompt "Bluetooth (off)" --width 300 --lines 3)
    [ "$CHOICE" = "Turn On" ] && bluetoothctl power on
    exit
fi

# Get paired devices with connection status
DEVICES=$(bluetoothctl devices Paired 2>/dev/null | while read -r _ mac name; do
    status=$(bluetoothctl info "$mac" | grep -i "Connected:" | awk '{print $2}')
    if [ "$status" = "yes" ]; then
        echo "[on]  $name|$mac"
    else
        echo "[off] $name|$mac"
    fi
done)

MENU="[scan] Scan for new devices\n[off]  Turn Bluetooth Off\n$DEVICES"

SELECTED=$(printf "%b" "$MENU" | wofi --dmenu --prompt "Bluetooth" --width 350 --lines 10 --no-actions)
[ -z "$SELECTED" ] && exit

if [[ "$SELECTED" == "[off]"* ]]; then
    bluetoothctl power off
    exit
fi

if [[ "$SELECTED" == "[scan]"* ]]; then
    # Scan and show discovered devices in a second menu
    notify-send "Bluetooth" "Scanning for 8 seconds..." 2>/dev/null
    bluetoothctl scan on &
    SCAN_PID=$!
    sleep 8
    kill $SCAN_PID 2>/dev/null
    bluetoothctl scan off 2>/dev/null

    NEW=$(bluetoothctl devices | while read -r _ mac name; do
        paired=$(bluetoothctl info "$mac" | grep -i "Paired:" | awk '{print $2}')
        [ "$paired" = "yes" ] && continue
        echo "$name|$mac"
    done)

    [ -z "$NEW" ] && notify-send "Bluetooth" "No new devices found." && exit

    PICK=$(echo "$NEW" | awk -F'|' '{print $1}' | wofi --dmenu --prompt "Pair device" --width 350 --lines 10)
    [ -z "$PICK" ] && exit
    MAC=$(echo "$NEW" | grep "^$PICK|" | cut -d'|' -f2)
    bluetoothctl pair "$MAC" && bluetoothctl connect "$MAC"
    exit
fi

# Connect/disconnect a paired device
MAC=$(echo "$SELECTED" | sed 's/\[o[nf]*\]  //' | cut -d'|' -f2)
NAME=$(echo "$SELECTED" | sed 's/\[o[nf]*\]  //' | cut -d'|' -f1)
STATUS=$(echo "$SELECTED" | grep -o '^\[o[nf]*\]' | tr -d '[]')

if [ "$STATUS" = "on" ]; then
    bluetoothctl disconnect "$MAC"
else
    bluetoothctl connect "$MAC"
fi
