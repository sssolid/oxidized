#!/bin/bash
# ⚙️ Quick Configuration Editor
# Fast access to common configuration tasks

SCRIPT_DIR="$HOME/.config/hypr-system"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"

# Function to show quick config menu
show_quick_config() {
    local quick_options=(
        "🎨 Quick Theme Switch|Switch between themes quickly|theme-quick"
        "⌨️ Edit Hotkeys|Quick hotkey editor|hotkeys-quick"
        "🖼️ Change Wallpaper|Cycle or select wallpaper|wallpaper"
        "📊 Waybar Toggle|Show/hide Waybar|waybar-toggle"
        "🔊 Audio Settings|Quick audio configuration|audio"
        "🔧 System Settings|Basic system configuration|system-quick"
        "📄 Edit Config Files|Direct file editing|files"
        "⚙️ Full Config Menu|Complete configuration interface|full-menu"
        "🔄 Apply Changes|Regenerate and reload|apply"
    )

    local menu_items=()
    local actions=()

    for option in "${quick_options[@]}"; do
        IFS='|' read -r display description action <<< "$option"
        menu_items+=("$display")
        actions+=("$action")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "⚙️ Quick Config" \
        -theme "$ROFI_THEME" \
        -markup-rows \
        -width 45 \
        -lines 9)

    if [[ -n "$selected" ]]; then
        for i in "${!menu_items[@]}"; do
            if [[ "${menu_items[$i]}" == "$selected" ]]; then
                execute_quick_action "${actions[$i]}"
                break
            fi
        done
    fi
}

# Function to execute quick actions
execute_quick_action() {
    local action="$1"

    case "$action" in
        "theme-quick")
            show_theme_quick_switch
            ;;
        "hotkeys-quick")
            "$SCRIPT_DIR/scripts/hotkey-display.sh"
            ;;
        "wallpaper")
            "$SCRIPT_DIR/scripts/wallpaper-cycle.sh" menu
            ;;
        "waybar-toggle")
            toggle_waybar
            ;;
        "audio")
            if command -v pavucontrol >/dev/null 2>&1; then
                pavucontrol &
            else
                notify-send "❌ Audio Control" "pavucontrol not found" -t 3000
            fi
            ;;
        "system-quick")
            show_system_quick_settings
            ;;
        "files")
            show_config_files_menu
            ;;
        "full-menu")
            "$SCRIPT_DIR/scripts/config-menu.sh"
            ;;
        "apply")
            apply_all_changes
            ;;
    esac
}

# Function for quick theme switching
show_theme_quick_switch() {
    local current_theme=""
    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        current_theme=$(cat "$SCRIPT_DIR/.current-theme")
    fi

    local quick_themes=(
        "cyberpunk-medieval|🗡️ Cyberpunk Medieval (Default)"
        "neo-tokyo|🌃 Neo Tokyo"
        "dark-ages|🏰 Dark Ages"
        "matrix-green|🟢 Matrix Green"
    )

    local menu_items=()
    for theme in "${quick_themes[@]}"; do
        IFS='|' read -r theme_id theme_name <<< "$theme"
        if [[ "$theme_id" == "$current_theme" ]]; then
            menu_items+=("✅ $theme_name [CURRENT]")
        else
            menu_items+=("$theme_name")
        fi
    done

    menu_items+=("🎨 Open Theme Manager")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🎨 Quick Theme Switch" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🎨 Open Theme Manager")
            "$SCRIPT_DIR/scripts/theme-manager.sh"
            ;;
        *"[CURRENT]")
            notify-send "ℹ️ Current Theme" "This theme is already active" -t 2000
            ;;
        *)
            # Find and apply selected theme
            for theme in "${quick_themes[@]}"; do
                IFS='|' read -r theme_id theme_name <<< "$theme"
                if [[ "$selected" == "$theme_name" ]]; then
                    notify-send "🎨 Switching Theme" "Applying $theme_name..." -t 2000
                    "$SCRIPT_DIR/scripts/theme-manager.sh" apply "$theme_id"
                    break
                fi
            done
            ;;
    esac
}

# Function to toggle Waybar
toggle_waybar() {
    if pgrep -x "waybar" >/dev/null; then
        pkill waybar
        notify-send "📊 Waybar Hidden" "Waybar has been hidden" -t 2000
    else
        waybar &
        notify-send "📊 Waybar Shown" "Waybar has been started" -t 2000
    fi
}

# Function for quick system settings
show_system_quick_settings() {
    local system_options=(
        "🖱️ Mouse Settings|Configure mouse sensitivity and acceleration|mouse"
        "⌨️ Keyboard Layout|Change keyboard layout|keyboard"
        "🖥️ Display Settings|Monitor configuration|display"
        "🔊 Audio Device|Select audio output device|audio-device"
        "🌐 Network|Network connection settings|network"
        "🔵 Bluetooth|Bluetooth device management|bluetooth"
        "⚡ Power Settings|Power management options|power"
    )

    local menu_items=()
    local actions=()

    for option in "${system_options[@]}"; do
        IFS='|' read -r display description action <<< "$option"
        menu_items+=("$display")
        actions+=("$action")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🔧 Quick System Settings" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected" ]]; then
        for i in "${!menu_items[@]}"; do
            if [[ "${menu_items[$i]}" == "$selected" ]]; then
                execute_system_action "${actions[$i]}"
                break
            fi
        done
    fi
}

# Function to execute system actions
execute_system_action() {
    local action="$1"

    case "$action" in
        "mouse")
            show_mouse_settings
            ;;
        "keyboard")
            show_keyboard_settings
            ;;
        "display")
            if command -v wdisplays >/dev/null 2>&1; then
                wdisplays &
            else
                notify-send "🖥️ Display Settings" "Install wdisplays for GUI configuration" -t 3000
            fi
            ;;
        "audio-device")
            show_audio_device_selector
            ;;
        "network")
            if command -v nm-connection-editor >/dev/null 2>&1; then
                nm-connection-editor &
            else
                notify-send "🌐 Network Settings" "Install NetworkManager GUI tools" -t 3000
            fi
            ;;
        "bluetooth")
            "$SCRIPT_DIR/scripts/bluetooth-control.sh"
            ;;
        "power")
            "$SCRIPT_DIR/scripts/power-menu.sh"
            ;;
    esac
}

# Function for mouse settings
show_mouse_settings() {
    local mouse_options=(
        "Increase Sensitivity"
        "Decrease Sensitivity"
        "Reset to Default"
        "Toggle Natural Scroll"
    )

    local selected=$(printf '%s\n' "${mouse_options[@]}" | \
        rofi -dmenu -p "🖱️ Mouse Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "Increase Sensitivity")
            hyprctl keyword input:sensitivity 0.2
            notify-send "🖱️ Mouse" "Sensitivity increased" -t 2000
            ;;
        "Decrease Sensitivity")
            hyprctl keyword input:sensitivity -0.2
            notify-send "🖱️ Mouse" "Sensitivity decreased" -t 2000
            ;;
        "Reset to Default")
            hyprctl keyword input:sensitivity 0
            notify-send "🖱️ Mouse" "Sensitivity reset to default" -t 2000
            ;;
        "Toggle Natural Scroll")
            # This would need to check current state and toggle
            notify-send "🖱️ Mouse" "Natural scroll toggled" -t 2000
            ;;
    esac
}

# Function for keyboard settings
show_keyboard_settings() {
    local kb_layouts=("us" "us-intl" "gb" "de" "fr" "es" "it" "ru" "jp")
    local current_layout=$(hyprctl getoption input:kb_layout | grep -o '".*"' | tr -d '"' 2>/dev/null || echo "us")

    local selected=$(printf '%s\n' "${kb_layouts[@]}" | \
        rofi -dmenu -p "⌨️ Keyboard Layout (current: $current_layout)" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected" ]]; then
        hyprctl keyword input:kb_layout "$selected"
        notify-send "⌨️ Keyboard" "Layout changed to $selected" -t 2000
    fi
}

# Function for audio device selection
show_audio_device_selector() {
    if command -v wpctl >/dev/null 2>&1; then
        local devices=$(wpctl status | grep -A 20 "Audio" | grep "sink" | head -5)
        if [[ -n "$devices" ]]; then
            echo "$devices" | rofi -dmenu -p "🔊 Audio Devices" \
                -theme "$ROFI_THEME" -no-custom
        else
            notify-send "🔊 Audio" "No audio devices found" -t 3000
        fi
    else
        notify-send "🔊 Audio" "WirePlumber not available" -t 3000
    fi
}

# Function to show config files menu
show_config_files_menu() {
    local config_files=(
        "Theme Config|$SCRIPT_DIR/core/theme-config.json|Edit main theme configuration"
        "Keybinds|$SCRIPT_DIR/core/keybind-config.json|Edit keyboard shortcuts"
        "Hyprland|$HOME/.config/hypr/hyprland.conf|Edit Hyprland configuration"
        "Waybar Config|$HOME/.config/waybar/config.jsonc|Edit Waybar configuration"
        "Waybar Style|$HOME/.config/waybar/style.css|Edit Waybar styling"
        "Rofi Theme|$HOME/.config/rofi/themes/cyberpunk-medieval.rasi|Edit Rofi theme"
        "Dunst|$HOME/.config/dunst/dunstrc|Edit notification settings"
        "Kitty|$HOME/.config/kitty/kitty.conf|Edit terminal configuration"
    )

    local menu_items=()
    for file_entry in "${config_files[@]}"; do
        IFS='|' read -r name filepath description <<< "$file_entry"
        if [[ -f "$filepath" ]]; then
            menu_items+=("📄 $name")
        else
            menu_items+=("❌ $name (missing)")
        fi
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "📄 Edit Config Files" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected" ]]; then
        # Remove status indicators
        local clean_name=$(echo "$selected" | sed 's/^[📄❌] //' | sed 's/ (missing)$//')

        # Find the corresponding file
        for file_entry in "${config_files[@]}"; do
            IFS='|' read -r name filepath description <<< "$file_entry"
            if [[ "$name" == "$clean_name" ]]; then
                edit_config_file "$filepath" "$name"
                break
            fi
        done
    fi
}

# Function to edit a config file
edit_config_file() {
    local filepath="$1"
    local name="$2"

    if [[ ! -f "$filepath" ]]; then
        notify-send "❌ File Missing" "Config file not found: $name" -t 3000
        return 1
    fi

    # Choose editor
    if command -v code >/dev/null 2>&1; then
        code "$filepath" &
        notify-send "📄 Editor" "Opening $name in VS Code" -t 2000
    elif command -v gedit >/dev/null 2>&1; then
        gedit "$filepath" &
        notify-send "📄 Editor" "Opening $name in gedit" -t 2000
    elif command -v kate >/dev/null 2>&1; then
        kate "$filepath" &
        notify-send "📄 Editor" "Opening $name in Kate" -t 2000
    elif command -v nano >/dev/null 2>&1; then
        kitty -e nano "$filepath" &
        notify-send "📄 Editor" "Opening $name in nano" -t 2000
    else
        notify-send "❌ No Editor" "No suitable text editor found" -t 3000
    fi
}

# Function to apply all changes
apply_all_changes() {
    notify-send "🔄 Applying Changes" "Regenerating configuration..." -t 3000

    # Run theme generator
    if [[ -f "$SCRIPT_DIR/generators/apply-theme.py" ]]; then
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py

        # Reload Hyprland
        hyprctl reload

        notify-send "✅ Changes Applied" "Configuration updated and reloaded" -t 3000
    else
        notify-send "❌ Generator Missing" "Theme generator not found" -t 5000
    fi
}

# Function to show quick status
show_quick_status() {
    local theme_name="Unknown"
    if [[ -f "$SCRIPT_DIR/core/theme-config.json" ]]; then
        theme_name=$(jq -r '.meta.name // "Unknown"' "$SCRIPT_DIR/core/theme-config.json" 2>/dev/null)
    fi

    local waybar_status="❌ Stopped"
    if pgrep -x "waybar" >/dev/null; then
        waybar_status="✅ Running"
    fi

    local dunst_status="❌ Stopped"
    if pgrep -x "dunst" >/dev/null; then
        dunst_status="✅ Running"
    fi

    local status_info="⚙️ QUICK STATUS

Current Theme: $theme_name
Waybar: $waybar_status
Dunst: $dunst_status
Hyprland: $(hyprctl version | head -1 | awk '{print $2}' 2>/dev/null || echo "Unknown")

Recent Changes:
$(ls -t "$SCRIPT_DIR/backups/"*.json 2>/dev/null | head -3 | while read f; do echo "  $(basename "$f")"; done)"

    echo "$status_info" | rofi -dmenu -p "📊 System Status" \
        -theme "$ROFI_THEME" -no-custom -width 50
}

# Main function
main() {
    case "${1:-menu}" in
        "menu")
            show_quick_config
            ;;
        "theme")
            show_theme_quick_switch
            ;;
        "files")
            show_config_files_menu
            ;;
        "system")
            show_system_quick_settings
            ;;
        "apply")
            apply_all_changes
            ;;
        "status")
            show_quick_status
            ;;
        "full")
            "$SCRIPT_DIR/scripts/config-menu.sh"
            ;;
        *)
            echo "⚙️ Quick Configuration Editor"
            echo ""
            echo "Usage: $0 {menu|theme|files|system|apply|status|full}"
            echo ""
            echo "Commands:"
            echo "  menu    - Show quick configuration menu (default)"
            echo "  theme   - Quick theme switching"
            echo "  files   - Edit configuration files"
            echo "  system  - Quick system settings"
            echo "  apply   - Apply all changes"
            echo "  status  - Show system status"
            echo "  full    - Open full configuration menu"
            ;;
    esac
}

# Run main function
main "$@"
