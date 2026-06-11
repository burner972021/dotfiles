#!/usr/bin/env bash
# Toggle mute via PipeWire (keeps waybar/PipeWire as source of truth) and mirror
# the result onto the ALSA hardware control so the ThinkPad mute / mic-mute LED
# follows (the LEDs are driven by snd_ctl_led watching the ALSA switch).
#
# Usage: mute-toggle.sh sink|source

CARD=1

case "$1" in
    sink)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
            amixer -c$CARD sset Master mute >/dev/null
        else
            amixer -c$CARD sset Master unmute >/dev/null
        fi
        ;;
    source)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
            amixer -c$CARD sset Capture nocap >/dev/null
        else
            amixer -c$CARD sset Capture cap >/dev/null
        fi
        ;;
    *)
        echo "usage: $0 sink|source" >&2
        exit 1
        ;;
esac
