#!/bin/bash
# Toggle: power-saver → balanced → performance → power-saver
current=$(powerprofilesctl get)
case "$current" in
    power-saver) next="balanced" ;;
    balanced)    next="performance" ;;
    *)           next="power-saver" ;;
esac
powerprofilesctl set "$next"
