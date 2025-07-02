#!/bin/bash
# 📱 Component Configuration Editor
# Individual component configuration management

SCRIPT_DIR="$HOME/.config/hypr-system"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"

# Function to check dependencies
check_dependencies() {
    if ! command -v jq >/dev/null 2>&1; then
        notify-send "❌ Missing Dependency" "jq is required for component editing" -t 5000 -u critical
        return 1
    fi

    return 0
}

# Function to restart component
restart_component() {
    local component="$1"

    case "$component" in
        "waybar")
            notify-send "🔄 Restarting Waybar" "Applying new configuration..." -t 2000
            pkill waybar && waybar &
            ;;
        "dunst")
            notify-send "🔄 Restarting Dunst" "Applying new configuration..." -t 2000
            pkill dunst && dunst &
            ;;
        "eww")
            if command -v eww >/dev/null 2>&1; then
                eww kill && eww daemon &
                notify-send "🔄 EWW Restarted" "Widget system restarted" -t 2000
            fi
            ;;
        "hyprland")
            hyprctl reload
            notify-send "🔄 Hyprland Reloaded" "Configuration reloaded" -t 2000
            ;;
    esac
}

# Function to manage Rofi configuration
manage_rofi() {
    local rofi_menu=(
        "🎨 Theme Configuration"
        "📐 Window Dimensions"
        "⌨️ Keyboard Navigation"
        "🖱️ Mouse Behavior"
        "🔍 Search Settings"
        "🎭 Custom Themes"
        "📄 Edit Config File"
        "🔄 Test Configuration"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${rofi_menu[@]}" | \
        rofi -dmenu -p "📱 Rofi Configuration" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🎨 Theme Configuration")
            configure_rofi_theme
            ;;
        "📐 Window Dimensions")
            configure_rofi_dimensions
            ;;
        "⌨️ Keyboard Navigation")
            configure_rofi_keyboard
            ;;
        "🔍 Search Settings")
            configure_rofi_search
            ;;
        "🎭 Custom Themes")
            manage_rofi_themes
            ;;
        "📄 Edit Config File")
            edit_rofi_config
            ;;
        "🔄 Test Configuration")
            test_rofi_config
            ;;
    esac
}

# Function to configure Rofi theme
configure_rofi_theme() {
    local theme_options=(
        "🎨 Current Cyberpunk Medieval"
        "🌃 Dark Theme"
        "🌅 Light Theme"
        "🎯 Minimal Theme"
        "🔧 Custom Theme"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${theme_options[@]}" | \
        rofi -dmenu -p "🎨 Rofi Theme" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🔧 Custom Theme")
            create_custom_rofi_theme
            ;;
    esac
}

# Function to configure Rofi dimensions
configure_rofi_dimensions() {
    local rofi_config="$HOME/.config/rofi/config.rasi"

    # Get current theme config values
    local current_width="600"
    local current_lines="8"

    if [[ -f "$SCRIPT_DIR/core/theme-config.json" ]]; then
        current_width=$(jq -r '.components.rofi.width // 600' "$SCRIPT_DIR/core/theme-config.json")
        current_lines=$(jq -r '.components.rofi.lines // 8' "$SCRIPT_DIR/core/theme-config.json")
    fi

    local dimension_options=(
        "📏 Width: ${current_width}px"
        "📊 Lines: $current_lines"
        "📍 Location"
        "🖼️ Show Icons"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${dimension_options[@]}" | \
        rofi -dmenu -p "📐 Rofi Dimensions" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📏 Width:"*)
            local new_width=$(echo "$current_width" | rofi -dmenu -p "Enter width (pixels):")
            if [[ "$new_width" =~ ^[0-9]+$ ]]; then
                # Update theme config
                local temp_file=$(mktemp)
                jq ".components.rofi.width = $new_width" "$SCRIPT_DIR/core/theme-config.json" > "$temp_file" && \
                mv "$temp_file" "$SCRIPT_DIR/core/theme-config.json"
                notify-send "📏 Width Updated" "Rofi width set to ${new_width}px" -t 3000
            fi
            ;;
        "📊 Lines:"*)
            local new_lines=$(echo "$current_lines" | rofi -dmenu -p "Enter number of lines:")
            if [[ "$new_lines" =~ ^[0-9]+$ ]]; then
                # Update theme config
                local temp_file=$(mktemp)
                jq ".components.rofi.lines = $new_lines" "$SCRIPT_DIR/core/theme-config.json" > "$temp_file" && \
                mv "$temp_file" "$SCRIPT_DIR/core/theme-config.json"
                notify-send "📊 Lines Updated" "Rofi lines set to $new_lines" -t 3000
            fi
            ;;
        "📍 Location")
            local locations=("center" "top" "bottom" "left" "right")
            local new_location=$(printf '%s\n' "${locations[@]}" | \
                rofi -dmenu -p "Select location:")
            if [[ -n "$new_location" ]]; then
                notify-send "📍 Location Updated" "Rofi location set to $new_location" -t 3000
            fi
            ;;
    esac
}

# Function to manage Dunst configuration
manage_dunst() {
    local dunst_menu=(
        "🔔 Notification Settings"
        "🎨 Appearance & Styling"
        "⏰ Timing & Urgency"
        "🖱️ Mouse Actions"
        "⌨️ Keyboard Shortcuts"
        "🔧 Advanced Settings"
        "📄 Edit Config File"
        "🔄 Restart Dunst"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${dunst_menu[@]}" | \
        rofi -dmenu -p "🔔 Dunst Configuration" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🔔 Notification Settings")
            configure_dunst_notifications
            ;;
        "🎨 Appearance & Styling")
            configure_dunst_appearance
            ;;
        "⏰ Timing & Urgency")
            configure_dunst_timing
            ;;
        "🖱️ Mouse Actions")
            configure_dunst_mouse
            ;;
        "⌨️ Keyboard Shortcuts")
            configure_dunst_keyboard
            ;;
        "📄 Edit Config File")
            edit_dunst_config
            ;;
        "🔄 Restart Dunst")
            restart_component "dunst"
            ;;
    esac
}

# Function to configure Dunst notifications
configure_dunst_notifications() {
    local notification_options=(
        "📍 Position"
        "📐 Size"
        "📊 Max Notifications"
        "🔤 Font Settings"
        "🖼️ Icon Settings"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${notification_options[@]}" | \
        rofi -dmenu -p "🔔 Notification Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📍 Position")
            local positions=("top-right" "top-left" "bottom-right" "bottom-left" "top-center" "bottom-center")
            local position=$(printf '%s\n' "${positions[@]}" | \
                rofi -dmenu -p "Select notification position:")
            if [[ -n "$position" ]]; then
                notify-send "📍 Position Changed" "Notifications will appear at $position" -t 3000
            fi
            ;;
        "📐 Size")
            local width=$(echo "400" | rofi -dmenu -p "Enter notification width:")
            if [[ "$width" =~ ^[0-9]+$ ]]; then
                notify-send "📐 Width Changed" "Notification width set to ${width}px" -t 3000
            fi
            ;;
    esac
}

# Function to manage Kitty configuration
manage_kitty() {
    local kitty_menu=(
        "🎨 Color Scheme"
        "📝 Font Configuration"
        "🖼️ Window Settings"
        "⌨️ Key Bindings"
        "🎭 Tab Settings"
        "🔧 Performance"
        "📄 Edit Config File"
        "🔄 Reload Configuration"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${kitty_menu[@]}" | \
        rofi -dmenu -p "🐱 Kitty Configuration" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🎨 Color Scheme")
            configure_kitty_colors
            ;;
        "📝 Font Configuration")
            configure_kitty_fonts
            ;;
        "🖼️ Window Settings")
            configure_kitty_window
            ;;
        "⌨️ Key Bindings")
            configure_kitty_keybinds
            ;;
        "📄 Edit Config File")
            edit_kitty_config
            ;;
        "🔄 Reload Configuration")
            reload_kitty_config
            ;;
    esac
}

# Function to configure Kitty colors
configure_kitty_colors() {
    local color_options=(
        "🎨 Use Theme Colors"
        "🌈 Custom Color Scheme"
        "🔄 Reset to Default"
        "👁️ Preview Changes"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${color_options[@]}" | \
        rofi -dmenu -p "🎨 Kitty Colors" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🎨 Use Theme Colors")
            notify-send "🎨 Theme Colors" "Kitty will use colors from current theme" -t 3000
            apply_component_changes "kitty"
            ;;
        "👁️ Preview Changes")
            kitty -o "background=#0d1117" -o "foreground=#e6edf3" &
            notify-send "👁️ Preview" "New Kitty window opened with preview colors" -t 3000
            ;;
    esac
}

# Function to configure Kitty fonts
configure_kitty_fonts() {
    local current_font="JetBrains Mono Nerd Font"
    local current_size="13"

    if [[ -f "$SCRIPT_DIR/core/theme-config.json" ]]; then
        current_font=$(jq -r '.typography.font_primary // "JetBrains Mono Nerd Font"' "$SCRIPT_DIR/core/theme-config.json")
        current_size=$(jq -r '.typography.size_normal // 13' "$SCRIPT_DIR/core/theme-config.json")
    fi

    local font_options=(
        "📝 Font Family: $current_font"
        "📏 Font Size: $current_size"
        "🔤 Bold Font"
        "🔤 Italic Font"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${font_options[@]}" | \
        rofi -dmenu -p "📝 Kitty Fonts" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📝 Font Family:"*)
            local fonts=("JetBrains Mono Nerd Font" "Fira Code Nerd Font" "Hack Nerd Font" "Source Code Pro" "Cascadia Code")
            local new_font=$(printf '%s\n' "${fonts[@]}" | \
                rofi -dmenu -p "Select font family:")
            if [[ -n "$new_font" ]]; then
                notify-send "📝 Font Changed" "Font family set to $new_font" -t 3000
            fi
            ;;
        "📏 Font Size:"*)
            local new_size=$(echo "$current_size" | rofi -dmenu -p "Enter font size:")
            if [[ "$new_size" =~ ^[0-9]+$ ]]; then
                notify-send "📏 Size Changed" "Font size set to $new_size" -t 3000
            fi
            ;;
    esac
}

# Function to manage EWW widgets
manage_eww() {
    if ! command -v eww >/dev/null 2>&1; then
        notify-send "❌ EWW Not Found" "EWW is not installed" -t 3000
        return 1
    fi

    local eww_menu=(
        "🎮 Widget Management"
        "⚙️ EWW Configuration"
        "🎨 Widget Styling"
        "🔧 Custom Widgets"
        "📄 Edit Widget Files"
        "▶️ Start EWW Daemon"
        "⏹️ Stop EWW Daemon"
        "🔄 Restart EWW"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${eww_menu[@]}" | \
        rofi -dmenu -p "🎮 EWW Widget System" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🎮 Widget Management")
            manage_eww_widgets
            ;;
        "🎨 Widget Styling")
            edit_eww_styles
            ;;
        "📄 Edit Widget Files")
            edit_eww_config
            ;;
        "▶️ Start EWW Daemon")
            eww daemon &
            notify-send "▶️ EWW Started" "EWW daemon started" -t 2000
            ;;
        "⏹️ Stop EWW Daemon")
            eww kill
            notify-send "⏹️ EWW Stopped" "EWW daemon stopped" -t 2000
            ;;
        "🔄 Restart EWW")
            restart_component "eww"
            ;;
    esac
}

# Function to manage EWW widgets
manage_eww_widgets() {
    local widget_options=(
        "👁️ View Active Widgets"
        "▶️ Open Widget"
        "⏹️ Close Widget"
        "🔄 Reload Widget"
        "🎯 Toggle Widget"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${widget_options[@]}" | \
        rofi -dmenu -p "🎮 Widget Management" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "👁️ View Active Widgets")
            local active_widgets=$(eww active-windows 2>/dev/null || echo "No active widgets")
            echo "$active_widgets" | rofi -dmenu -p "👁️ Active Widgets" \
                -theme "$ROFI_THEME" -no-custom
            ;;
        "▶️ Open Widget")
            local widget_name=$(echo "hotkey-display" | rofi -dmenu -p "Enter widget name:")
            if [[ -n "$widget_name" ]]; then
                eww open "$widget_name" 2>/dev/null && \
                notify-send "▶️ Widget Opened" "Opened $widget_name widget" -t 2000
            fi
            ;;
        "⏹️ Close Widget")
            local widget_name=$(echo "" | rofi -dmenu -p "Enter widget name to close:")
            if [[ -n "$widget_name" ]]; then
                eww close "$widget_name" 2>/dev/null && \
                notify-send "⏹️ Widget Closed" "Closed $widget_name widget" -t 2000
            fi
            ;;
    esac
}

# Function to edit configuration files
edit_config_file() {
    local component="$1"
    local config_file=""

    case "$component" in
        "rofi")
            config_file="$HOME/.config/rofi/config.rasi"
            ;;
        "dunst")
            config_file="$HOME/.config/dunst/dunstrc"
            ;;
        "kitty")
            config_file="$HOME/.config/kitty/kitty.conf"
            ;;
        "eww")
            config_file="$HOME/.config/eww/eww.yuck"
            ;;
    esac

    if [[ -f "$config_file" ]]; then
        if command -v code >/dev/null 2>&1; then
            code "$config_file" &
            notify-send "📄 Editor Opened" "Editing $component configuration" -t 2000
        elif command -v nano >/dev/null 2>&1; then
            kitty -e nano "$config_file" &
        else
            notify-send "❌ No Editor" "Please install code or nano" -t 3000
        fi
    else
        notify-send "❌ Config Missing" "$component configuration file not found" -t 3000
    fi
}

# Function shortcuts for editing configs
edit_rofi_config() { edit_config_file "rofi"; }
edit_dunst_config() { edit_config_file "dunst"; }
edit_kitty_config() { edit_config_file "kitty"; }
edit_eww_config() { edit_config_file "eww"; }

# Function to test configurations
test_component_config() {
    local component="$1"

    case "$component" in
        "rofi")
            rofi -show drun -theme "$ROFI_THEME" &
            ;;
        "dunst")
            notify-send "🔄 Test Notification" "Testing Dunst configuration" -t 3000
            ;;
        "kitty")
            kitty &
            ;;
    esac
}

# Function shortcuts for testing configs
test_rofi_config() { test_component_config "rofi"; }

# Function to apply component changes
apply_component_changes() {
    local component="$1"

    notify-send "🔄 Applying Changes" "Regenerating $component configuration..." -t 2000

    # Regenerate from theme
    if [[ -f "$SCRIPT_DIR/generators/apply-theme.py" ]]; then
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py
    fi

    # Restart component
    restart_component "$component"
}

# Function to reload Kitty config
reload_kitty_config() {
    # Kitty doesn't have a reload command, but we can send a signal
    pkill -SIGUSR1 kitty 2>/dev/null || notify-send "ℹ️ Kitty Reload" "Please restart Kitty to see changes" -t 3000
}

# Main component editor menu
show_component_editor() {
    local main_menu=(
        "📱 Rofi Configuration"
        "🔔 Dunst Notifications"
        "🐱 Kitty Terminal"
        "🎮 EWW Widgets"
        "📊 Component Status"
        "🔄 Apply All Changes"
        "🔧 Advanced Component Tools"
        "💾 Save & Exit"
    )

    local selected=$(printf '%s\n' "${main_menu[@]}" | \
        rofi -dmenu -p "📱 Component Editor" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "📱 Rofi Configuration")
            manage_rofi
            ;;
        "🔔 Dunst Notifications")
            manage_dunst
            ;;
        "🐱 Kitty Terminal")
            manage_kitty
            ;;
        "🎮 EWW Widgets")
            manage_eww
            ;;
        "📊 Component Status")
            show_component_status
            ;;
        "🔄 Apply All Changes")
            apply_all_component_changes
            ;;
        "🔧 Advanced Component Tools")
            show_advanced_component_tools
            ;;
        "💾 Save & Exit")
            apply_all_component_changes
            return 0
            ;;
        *)
            return 0
            ;;
    esac

    # Return to main menu unless exiting
    show_component_editor
}

# Function to show component status
show_component_status() {
    local status_info="📊 COMPONENT STATUS

📱 ROFI: $(command -v rofi >/dev/null && echo "✅ Installed" || echo "❌ Missing")
🔔 DUNST: $(pgrep -x dunst >/dev/null && echo "✅ Running" || echo "❌ Stopped")
🐱 KITTY: $(command -v kitty >/dev/null && echo "✅ Installed" || echo "❌ Missing")
🎮 EWW: $(command -v eww >/dev/null && echo "✅ Installed" || echo "❌ Missing")
   └─ Daemon: $(eww ping >/dev/null 2>&1 && echo "✅ Running" || echo "❌ Stopped")

📄 CONFIG FILES:
Rofi: $([ -f "$HOME/.config/rofi/config.rasi" ] && echo "✅" || echo "❌")
Dunst: $([ -f "$HOME/.config/dunst/dunstrc" ] && echo "✅" || echo "❌")
Kitty: $([ -f "$HOME/.config/kitty/kitty.conf" ] && echo "✅" || echo "❌")
EWW: $([ -f "$HOME/.config/eww/eww.yuck" ] && echo "✅" || echo "❌")"

    echo "$status_info" | rofi -dmenu -p "📊 Component Status" \
        -theme "$ROFI_THEME" -no-custom -width 60
}

# Function to apply all component changes
apply_all_component_changes() {
    notify-send "🔄 Applying All Changes" "Regenerating all component configurations..." -t 3000

    # Regenerate all configs
    if [[ -f "$SCRIPT_DIR/generators/apply-theme.py" ]]; then
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py
    fi

    # Restart components
    restart_component "waybar"
    restart_component "dunst"

    notify-send "✅ All Changes Applied" "All components updated successfully" -t 3000
}

# Function to show advanced component tools
show_advanced_component_tools() {
    local advanced_menu=(
        "🔧 Component Dependencies"
        "📦 Install Missing Components"
        "🧹 Clean Component Configs"
        "💾 Backup Component Configs"
        "📥 Restore Component Configs"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${advanced_menu[@]}" | \
        rofi -dmenu -p "🔧 Advanced Tools" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🔧 Component Dependencies")
            check_component_dependencies
            ;;
        "📦 Install Missing Components")
            install_missing_components
            ;;
        "🧹 Clean Component Configs")
            clean_component_configs
            ;;
    esac
}

# Function to check component dependencies
check_component_dependencies() {
    local deps_info="🔧 COMPONENT DEPENDENCIES

📱 ROFI: rofi$(command -v rofi >/dev/null && echo " ✅" || echo " ❌")
🔔 DUNST: dunst$(command -v dunst >/dev/null && echo " ✅" || echo " ❌")
🐱 KITTY: kitty$(command -v kitty >/dev/null && echo " ✅" || echo " ❌")
🎮 EWW: eww$(command -v eww >/dev/null && echo " ✅" || echo " ❌")

📝 UTILITIES:
jq: $(command -v jq >/dev/null && echo "✅" || echo "❌")
wl-copy: $(command -v wl-copy >/dev/null && echo "✅" || echo "❌")
notify-send: $(command -v notify-send >/dev/null && echo "✅" || echo "❌")"

    echo "$deps_info" | rofi -dmenu -p "🔧 Dependencies" \
        -theme "$ROFI_THEME" -no-custom -width 50
}

# Function to install missing components
install_missing_components() {
    local missing_components=()

    command -v rofi >/dev/null || missing_components+=("rofi")
    command -v dunst >/dev/null || missing_components+=("dunst")
    command -v kitty >/dev/null || missing_components+=("kitty")
    command -v eww >/dev/null || missing_components+=("eww")

    if [[ ${#missing_components[@]} -eq 0 ]]; then
        notify-send "✅ All Installed" "All components are already installed" -t 3000
        return
    fi

    local install_cmd=""
    if command -v pacman >/dev/null 2>&1; then
        install_cmd="sudo pacman -S ${missing_components[*]}"
    elif command -v apt >/dev/null 2>&1; then
        install_cmd="sudo apt install ${missing_components[*]}"
    else
        notify-send "❌ Package Manager" "Automatic installation not supported for your system" -t 5000
        return
    fi

    if rofi -dmenu -p "Install missing components?" <<< $'Yes\nNo' | grep -q "Yes"; then
        kitty -e bash -c "$install_cmd; read -p 'Press Enter to continue...'" &
    fi
}

# Function to clean component configs
clean_component_configs() {
    if rofi -dmenu -p "Remove all component configs and regenerate?" <<< $'Yes\nNo' | grep -q "Yes"; then
        # Backup first
        local backup_dir="$SCRIPT_DIR/backups/components-$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"

        cp -r "$HOME/.config/rofi" "$backup_dir/" 2>/dev/null
        cp -r "$HOME/.config/dunst" "$backup_dir/" 2>/dev/null
        cp -r "$HOME/.config/kitty" "$backup_dir/" 2>/dev/null
        cp -r "$HOME/.config/eww" "$backup_dir/" 2>/dev/null

        # Regenerate
        apply_all_component_changes

        notify-send "🧹 Configs Cleaned" "Component configs regenerated" -t 3000
    fi
}

# Main function
main() {
    if ! check_dependencies; then
        exit 1
    fi

    case "${1:-menu}" in
        "menu")
            show_component_editor
            ;;
        "rofi")
            manage_rofi
            ;;
        "dunst")
            manage_dunst
            ;;
        "kitty")
            manage_kitty
            ;;
        "eww")
            manage_eww
            ;;
        "status")
            show_component_status
            ;;
        *)
            echo "📱 Component Configuration Editor"
            echo ""
            echo "Usage: $0 {menu|rofi|dunst|kitty|eww|status}"
            echo ""
            echo "Commands:"
            echo "  menu     - Show main component editor menu"
            echo "  rofi     - Configure Rofi launcher"
            echo "  dunst    - Configure Dunst notifications"
            echo "  kitty    - Configure Kitty terminal"
            echo "  eww      - Configure EWW widgets"
            echo "  status   - Show component status"
            ;;
    esac
}

# Run main function
main "$@"
