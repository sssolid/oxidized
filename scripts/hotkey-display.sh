#!/bin/bash
# 🎮 Enhanced Hotkey Display
# Dynamically shows hotkeys using EWW or falls back to rofi

SCRIPT_DIR="$HOME/.config/hypr-system"
EWW_DIR="$HOME/.config/eww/hotkey-display"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"

show_notification() {
    notify-send "🗡️ Hotkeys" "$1" -t 3000 -u normal
}

# Check if EWW is available and configured
if command -v eww >/dev/null 2>&1 && [[ -f "$EWW_DIR/eww.yuck" ]]; then
    # Use EWW interface
    show_notification "Opening dynamic hotkey interface..."

    cd "$EWW_DIR" || exit 1

    # Check if EWW daemon is running
    if ! eww ping >/dev/null 2>&1; then
        eww daemon &
        sleep 1
    fi

    # Toggle hotkey display
    current_state=$(eww get hotkey-visible 2>/dev/null || echo "false")
    if [[ "$current_state" == "true" ]]; then
        eww update hotkey-visible=false
        show_notification "Hotkey display closed"
    else
        eww update hotkey-visible=true
        show_notification "Hotkey display opened"
    fi

elif command -v rofi >/dev/null 2>&1; then
    # Fallback to rofi with enhanced display
    show_notification "Using rofi hotkey display..."

    # Create temporary file with hotkeys
    temp_file=$(mktemp)

    # Add header
    echo "🗡️ CYBERPUNK MEDIEVAL HOTKEYS 🤖" > "$temp_file"
    echo "════════════════════════════════════════" >> "$temp_file"
    echo "" >> "$temp_file"

    # Get hotkeys in rofi format
    "$SCRIPT_DIR/scripts/hotkey-parser.py" --rofi >> "$temp_file"

    # Show in rofi with custom theme
    rofi -dmenu \
         -p "🗡️ Hotkeys" \
         -theme "$HOME/.config/rofi/themes/cyberpunk-medieval.rasi" \
         -markup-rows \
         -no-custom \
         -width 80 \
         -lines 20 \
         -font "JetBrains Mono Nerd Font 12" < "$temp_file"

    # Cleanup
    rm -f "$temp_file"

else
    # Ultimate fallback - simple notification with basic info
    show_notification "Installing EWW or rofi for better hotkey display..."

    # Show basic hotkey info in notification
    count_info=$("$SCRIPT_DIR/scripts/hotkey-parser.py" --count)
    notify-send "⌨️ Hotkey Info" "$count_info\n\nInstall EWW or rofi for full interface" -t 5000
fi

# Optional: Play a sound effect if available
if command -v paplay >/dev/null 2>&1 && [[ -f "/usr/share/sounds/freedesktop/stereo/dialog-information.oga" ]]; then
    paplay /usr/share/sounds/freedesktop/stereo/dialog-information.oga 2>/dev/null &
fi
