#!/bin/bash

IFACE="wlp3s0"
CURRENT=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 | head -1)

# Refresh scan
nmcli dev wifi rescan 2>/dev/null &

# Build network list: current marked with *, sorted by signal strength
NETWORKS=$(nmcli -t -f ssid,signal,security dev wifi list ifname "$IFACE" 2>/dev/null \
    | awk -F: '
        !seen[$1]++ && $1 != "" {
            security = ($3 != "" && $3 != "--") ? " [" $3 "]" : ""
            printf "%s  %s%%%s\n", $1, $2, security
        }
    ')

# Prepend disconnect option if connected
if [ -n "$CURRENT" ]; then
    MENU="[disconnect] $CURRENT\n$NETWORKS"
else
    MENU="$NETWORKS"
fi

SELECTED=$(printf "%b" "$MENU" | wofi --dmenu --prompt "WiFi" --width 350 --lines 10 --no-actions)

[ -z "$SELECTED" ] && exit

# Handle disconnect
if [[ "$SELECTED" == "[disconnect]"* ]]; then
    nmcli dev disconnect "$IFACE"
    exit
fi

# Extract SSID (strip signal/security suffix)
SSID=$(echo "$SELECTED" | sed 's/  [0-9]*%.*$//')

# Already connected
[ "$SSID" = "$CURRENT" ] && exit

# Connect — use saved profile if it exists, otherwise prompt for password
if nmcli -t -f name connection show | grep -qxF "$SSID"; then
    nmcli connection up "$SSID"
else
    PASS=$(wofi --dmenu --prompt "Password for: $SSID" --width 350 --lines 1 --password)
    [ -z "$PASS" ] && exit
    nmcli dev wifi connect "$SSID" password "$PASS" ifname "$IFACE"
fi
