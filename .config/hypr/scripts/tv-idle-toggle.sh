#!/bin/bash
# ~/.config/hypr/scripts/tv-idle-toggle.sh
# Вызывается из hyprland.lua при подключении/отключении ТВ.

PIDFILE="/tmp/hypridle-tv.pid"
CONF="$HOME/.config/hypr/hypridle-tv.conf"
MAIN_MONITOR="eDP-1"

case "$1" in
  start)
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      exit 0  # уже запущен
    fi
    hypridle -c "$CONF" &
    echo $! > "$PIDFILE"
    ;;
  stop)
    if [ -f "$PIDFILE" ]; then
      kill "$(cat "$PIDFILE")" 2>/dev/null
      rm -f "$PIDFILE"
    fi
    # На случай, если основной монитор остался выключенным - включаем обратно
    hyprctl dispatch dpms on,"$MAIN_MONITOR"
    ;;
  *)
    echo "usage: $0 {start|stop}"
    exit 1
    ;;
esac
