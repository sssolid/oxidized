#!/bin/bash

RECORD_DIR="$HOME/Videos/Recordings"
RECORD_PID="$HOME/.cache/waybar_recorder.pid"
RECORD_FILE="$RECORD_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"

mkdir -p "$RECORD_DIR"

function is_recording() {
  [[ -f "$RECORD_PID" ]] && kill -0 "$(cat "$RECORD_PID")" 2>/dev/null
}

case "$1" in
  status)
    if is_recording; then
      echo '{"text": "", "tooltip": "Recording... (click to open)", "class": "recording"}'
    else
      echo '{"text": "󰑋", "tooltip": "Not Recording", "class": "idle"}'
    fi
    ;;
  toggle)
    if is_recording; then
      kill "$(cat "$RECORD_PID")" && rm -f "$RECORD_PID"
    else
      wf-recorder -f "$RECORD_FILE" & echo $! > "$RECORD_PID"
    fi
    ;;
    open)
        if command -v thunar &>/dev/null; then
          thunar "$RECORD_DIR" &
        else
          xdg-open "$RECORD_DIR" &
        fi
        ;;
esac
