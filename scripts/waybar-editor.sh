#!/bin/bash
# 📊 Waybar Configuration Editor
# Visual interface for customizing Waybar modules and appearance

SCRIPT_DIR="$HOME/.config/hypr-system"
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
WAYBAR_CSS="$HOME/.config/waybar/style.css"
THEME_CONFIG="$SCRIPT_DIR/core/theme-config.json"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"

# Function to check dependencies
check_dependencies() {
    if ! command -v jq >/dev/null 2>&1; then
        notify-send "❌ Missing Dependency" "jq is required for Waybar editing" -t 5000 -u critical
        return 1
    fi

    if ! command -v waybar >/dev/null 2>&1; then
        notify-send "❌ Waybar Missing" "Waybar is not installed" -t 5000 -u critical
        return 1
    fi

    return 0
}

# Function to restart Waybar
restart_waybar() {
    notify-send "🔄 Restarting Waybar" "Applying new configuration..." -t 2000
    pkill waybar
    sleep 1
    waybar &
    disown
    sleep 2
    notify-send "✅ Waybar Restarted" "New configuration applied" -t 2000
}

# Function to get Waybar config value
get_waybar_config() {
    local key="$1"
    # Remove comments and parse JSON
    sed 's|//.*||g' "$WAYBAR_CONFIG" | jq -r "$key // empty" 2>/dev/null
}

# Function to set Waybar config value
set_waybar_config() {
    local key="$1"
    local value="$2"
    local temp_file=$(mktemp)

    # Remove comments, update JSON, then add comments back
    if sed 's|//.*||g' "$WAYBAR_CONFIG" | jq "$key = $value" > "$temp_file"; then
        # Add header comment
        echo "// 📊 Generated Waybar Config - Managed by Cyberpunk Medieval Setup" > "$WAYBAR_CONFIG"
        cat "$temp_file" >> "$WAYBAR_CONFIG"
        rm "$temp_file"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Function to manage Waybar modules
manage_modules() {
    local module_menu=(
        "⬅️ Left Modules"
        "🎯 Center Modules"
        "➡️ Right Modules"
        "➕ Add Custom Module"
        "🗑️ Remove Module"
        "⚙️ Configure Module"
        "🔙 Back to Main Menu"
    )

    local selected=$(printf '%s\n' "${module_menu[@]}" | \
        rofi -dmenu -p "📊 Waybar Modules" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "⬅️ Left Modules")
            manage_module_section "modules-left"
            ;;
        "🎯 Center Modules")
            manage_module_section "modules-center"
            ;;
        "➡️ Right Modules")
            manage_module_section "modules-right"
            ;;
        "➕ Add Custom Module")
            add_custom_module
            ;;
        "🗑️ Remove Module")
            remove_module
            ;;
        "⚙️ Configure Module")
            configure_module
            ;;
        "🔙 Back to Main Menu")
            return 0
            ;;
    esac
}

# Function to manage specific module section
manage_module_section() {
    local section="$1"
    local current_modules=($(get_waybar_config ".[\"$section\"][]" 2>/dev/null || echo ""))

    local section_name
    case "$section" in
        "modules-left") section_name="⬅️ Left" ;;
        "modules-center") section_name="🎯 Center" ;;
        "modules-right") section_name="➡️ Right" ;;
    esac

    local menu_items=()
    local index=0
    for module in "${current_modules[@]}"; do
        menu_items+=("📊 $((index+1)). $module")
        ((index++))
    done

    menu_items+=("➕ Add Module" "🔄 Reorder Modules" "🗑️ Clear All" "🔙 Back")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "$section_name Modules" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "➕ Add Module")
            add_module_to_section "$section"
            ;;
        "🔄 Reorder Modules")
            reorder_modules "$section"
            ;;
        "🗑️ Clear All")
            if rofi -dmenu -p "Clear all modules from $section_name?" <<< $'Yes\nNo' | grep -q "Yes"; then
                set_waybar_config ".[\"$section\"]" "[]"
                notify-send "🗑️ Modules Cleared" "All modules removed from $section_name" -t 3000
            fi
            ;;
        "🔙 Back")
            return 0
            ;;
        *)
            if [[ "$selected" =~ ^📊\ [0-9]+\.\ (.+)$ ]]; then
                local module_name="${BASH_REMATCH[1]}"
                configure_specific_module "$module_name"
            fi
            ;;
    esac

    # Return to same section unless going back
    if [[ "$selected" != "🔙 Back" ]]; then
        manage_module_section "$section"
    fi
}

# Function to add module to section
add_module_to_section() {
    local section="$1"

    local available_modules=(
        "clock"
        "battery"
        "network"
        "pulseaudio"
        "bluetooth"
        "cpu"
        "memory"
        "disk"
        "temperature"
        "backlight"
        "idle_inhibitor"
        "tray"
        "hyprland/workspaces"
        "hyprland/window"
        "hyprland/mode"
        "custom/power"
        "custom/weather"
        "custom/media"
        "custom/updates"
    )

    local selected_module=$(printf '%s\n' "${available_modules[@]}" | \
        rofi -dmenu -p "➕ Select Module to Add" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected_module" ]]; then
        # Get current modules
        local current_modules_json=$(get_waybar_config ".[\"$section\"]")

        # Add new module
        local updated_modules=$(echo "$current_modules_json" | jq ". + [\"$selected_module\"]")

        if set_waybar_config ".[\"$section\"]" "$updated_modules"; then
            notify-send "✅ Module Added" "Added $selected_module to $section" -t 3000

            # Ask if user wants to restart Waybar
            if rofi -dmenu -p "Restart Waybar to see changes?" <<< $'Yes\nNo' | grep -q "Yes"; then
                restart_waybar
            fi
        else
            notify-send "❌ Failed" "Could not add module" -t 3000
        fi
    fi
}

# Function to reorder modules
reorder_modules() {
    local section="$1"
    local current_modules=($(get_waybar_config ".[\"$section\"][]"))

    if [[ ${#current_modules[@]} -eq 0 ]]; then
        notify-send "❌ No Modules" "No modules to reorder in this section" -t 3000
        return 1
    fi

    notify-send "🔄 Reordering" "Select modules in desired order..." -t 3000

    local reordered_modules=()
    local remaining_modules=("${current_modules[@]}")

    while [[ ${#remaining_modules[@]} -gt 0 ]]; do
        local menu_items=()
        for module in "${remaining_modules[@]}"; do
            menu_items+=("📊 $module")
        done
        menu_items+=("✅ Finish Reordering")

        local selected=$(printf '%s\n' "${menu_items[@]}" | \
            rofi -dmenu -p "🔄 Reorder Modules (${#reordered_modules[@]}/${#current_modules[@]})" \
            -theme "$ROFI_THEME")

        if [[ "$selected" == "✅ Finish Reordering" ]]; then
            break
        elif [[ "$selected" =~ ^📊\ (.+)$ ]]; then
            local module_name="${BASH_REMATCH[1]}"
            reordered_modules+=("$module_name")

            # Remove from remaining
            local new_remaining=()
            for module in "${remaining_modules[@]}"; do
                if [[ "$module" != "$module_name" ]]; then
                    new_remaining+=("$module")
                fi
            done
            remaining_modules=("${new_remaining[@]}")
        else
            break
        fi
    done

    # Update configuration
    if [[ ${#reordered_modules[@]} -gt 0 ]]; then
        local modules_json=$(printf '%s\n' "${reordered_modules[@]}" | jq -R . | jq -s .)
        set_waybar_config ".[\"$section\"]" "$modules_json"
        notify-send "✅ Modules Reordered" "Module order updated" -t 3000
    fi
}

# Function to configure specific module
configure_specific_module() {
    local module_name="$1"

    local config_options=(
        "👁️ View Current Config"
        "✏️ Edit Configuration"
        "🎨 Style Options"
        "🔧 Advanced Settings"
        "🗑️ Remove from All Sections"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${config_options[@]}" | \
        rofi -dmenu -p "⚙️ Configure $module_name" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "👁️ View Current Config")
            view_module_config "$module_name"
            ;;
        "✏️ Edit Configuration")
            edit_module_config "$module_name"
            ;;
        "🎨 Style Options")
            edit_module_styling "$module_name"
            ;;
        "🔧 Advanced Settings")
            edit_advanced_module_settings "$module_name"
            ;;
        "🗑️ Remove from All Sections")
            remove_module_from_all "$module_name"
            ;;
    esac
}

# Function to view module config
view_module_config() {
    local module_name="$1"
    local config=$(get_waybar_config ".\"$module_name\"")

    if [[ -n "$config" && "$config" != "null" ]]; then
        echo "$config" | jq . | rofi -dmenu -p "👁️ $module_name Config" \
            -theme "$ROFI_THEME" -no-custom
    else
        notify-send "ℹ️ No Config" "Module $module_name has no custom configuration" -t 3000
    fi
}

# Function to edit module config
edit_module_config() {
    local module_name="$1"

    case "$module_name" in
        "clock")
            edit_clock_module
            ;;
        "battery")
            edit_battery_module
            ;;
        "network")
            edit_network_module
            ;;
        "pulseaudio")
            edit_pulseaudio_module
            ;;
        "bluetooth")
            edit_bluetooth_module
            ;;
        "hyprland/workspaces")
            edit_workspaces_module
            ;;
        *)
            edit_generic_module "$module_name"
            ;;
    esac
}

# Function to edit clock module
edit_clock_module() {
    local current_format=$(get_waybar_config '.clock.format // "{:%H:%M 🕐 %a %d %b}"')

    local format_options=(
        "{:%H:%M 🕐 %a %d %b}"
        "{:%H:%M:%S}"
        "{:%Y-%m-%d %H:%M}"
        "{:%I:%M %p}"
        "Custom Format"
    )

    local selected_format=$(printf '%s\n' "${format_options[@]}" | \
        rofi -dmenu -p "🕐 Clock Format" \
        -theme "$ROFI_THEME")

    if [[ "$selected_format" == "Custom Format" ]]; then
        selected_format=$(echo "$current_format" | rofi -dmenu -p "Enter custom format:")
    fi

    if [[ -n "$selected_format" ]]; then
        set_waybar_config '.clock.format' "\"$selected_format\""
        notify-send "🕐 Clock Updated" "Format set to: $selected_format" -t 3000
    fi
}

# Function to edit battery module
edit_battery_module() {
    local battery_settings=(
        "🔋 Format String"
        "⚠️ Warning Level"
        "🔴 Critical Level"
        "⚡ Charging Format"
        "🔌 Plugged Format"
    )

    local selected=$(printf '%s\n' "${battery_settings[@]}" | \
        rofi -dmenu -p "🔋 Battery Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🔋 Format String")
            local current_format=$(get_waybar_config '.battery.format // "{icon} {capacity}%"')
            local new_format=$(echo "$current_format" | rofi -dmenu -p "Enter battery format:")
            if [[ -n "$new_format" ]]; then
                set_waybar_config '.battery.format' "\"$new_format\""
            fi
            ;;
        "⚠️ Warning Level")
            local warning_level=$(echo "30" | rofi -dmenu -p "Enter warning level (%):")
            if [[ "$warning_level" =~ ^[0-9]+$ ]]; then
                set_waybar_config '.battery.states.warning' "$warning_level"
            fi
            ;;
        "🔴 Critical Level")
            local critical_level=$(echo "15" | rofi -dmenu -p "Enter critical level (%):")
            if [[ "$critical_level" =~ ^[0-9]+$ ]]; then
                set_waybar_config '.battery.states.critical' "$critical_level"
            fi
            ;;
    esac
}

# Function to edit network module
edit_network_module() {
    local network_settings=(
        "📶 WiFi Format"
        "🌐 Ethernet Format"
        "❌ Disconnected Format"
        "📡 Interface"
        "💾 Tooltip"
    )

    local selected=$(printf '%s\n' "${network_settings[@]}" | \
        rofi -dmenu -p "📶 Network Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📶 WiFi Format")
            local current_format=$(get_waybar_config '.network."format-wifi" // "📶 {signalStrength}%"')
            local new_format=$(echo "$current_format" | rofi -dmenu -p "Enter WiFi format:")
            if [[ -n "$new_format" ]]; then
                set_waybar_config '.network."format-wifi"' "\"$new_format\""
            fi
            ;;
        "🌐 Ethernet Format")
            local current_format=$(get_waybar_config '.network."format-ethernet" // "🌐 {ifname}"')
            local new_format=$(echo "$current_format" | rofi -dmenu -p "Enter Ethernet format:")
            if [[ -n "$new_format" ]]; then
                set_waybar_config '.network."format-ethernet"' "\"$new_format\""
            fi
            ;;
    esac
}

# Function to edit generic module
edit_generic_module() {
    local module_name="$1"

    local generic_options=(
        "📝 Format String"
        "⏱️ Update Interval"
        "🖱️ Click Action"
        "💾 Tooltip"
        "📊 Custom JSON Config"
    )

    local selected=$(printf '%s\n' "${generic_options[@]}" | \
        rofi -dmenu -p "⚙️ $module_name Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📝 Format String")
            local current_format=$(get_waybar_config ".\"$module_name\".format")
            local new_format=$(echo "$current_format" | rofi -dmenu -p "Enter format string:")
            if [[ -n "$new_format" ]]; then
                set_waybar_config ".\"$module_name\".format" "\"$new_format\""
            fi
            ;;
        "⏱️ Update Interval")
            local interval=$(echo "60" | rofi -dmenu -p "Enter update interval (seconds):")
            if [[ "$interval" =~ ^[0-9]+$ ]]; then
                set_waybar_config ".\"$module_name\".interval" "$interval"
            fi
            ;;
        "🖱️ Click Action")
            local action=$(echo "" | rofi -dmenu -p "Enter click command:")
            if [[ -n "$action" ]]; then
                set_waybar_config ".\"$module_name\".\"on-click\"" "\"$action\""
            fi
            ;;
        "📊 Custom JSON Config")
            edit_custom_module_json "$module_name"
            ;;
    esac
}

# Function to edit custom module JSON
edit_custom_module_json() {
    local module_name="$1"
    local current_config=$(get_waybar_config ".\"$module_name\"")

    # Create temporary file for editing
    local temp_file=$(mktemp --suffix=.json)
    echo "$current_config" | jq . > "$temp_file" 2>/dev/null || echo "{}" > "$temp_file"

    # Open in editor
    if command -v code >/dev/null 2>&1; then
        code "$temp_file"
        read -p "Press Enter when done editing..."
    elif command -v nano >/dev/null 2>&1; then
        nano "$temp_file"
    else
        notify-send "❌ No Editor" "Please install code or nano to edit JSON" -t 3000
        rm "$temp_file"
        return 1
    fi

    # Validate and apply
    if jq empty "$temp_file" 2>/dev/null; then
        local new_config=$(cat "$temp_file")
        set_waybar_config ".\"$module_name\"" "$new_config"
        notify-send "✅ Config Updated" "Module $module_name configuration updated" -t 3000
    else
        notify-send "❌ Invalid JSON" "Configuration not updated due to JSON errors" -t 3000
    fi

    rm "$temp_file"
}

# Function to manage Waybar appearance
manage_appearance() {
    local appearance_menu=(
        "📐 Bar Dimensions"
        "🎨 Colors & Themes"
        "📝 Fonts & Typography"
        "🖼️ Transparency & Effects"
        "📊 Module Spacing"
        "🔙 Back to Main Menu"
    )

    local selected=$(printf '%s\n' "${appearance_menu[@]}" | \
        rofi -dmenu -p "🎨 Waybar Appearance" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📐 Bar Dimensions")
            edit_bar_dimensions
            ;;
        "🎨 Colors & Themes")
            edit_waybar_colors
            ;;
        "📝 Fonts & Typography")
            edit_waybar_fonts
            ;;
        "🖼️ Transparency & Effects")
            edit_waybar_effects
            ;;
        "📊 Module Spacing")
            edit_module_spacing
            ;;
    esac
}

# Function to edit bar dimensions
edit_bar_dimensions() {
    local current_height=$(get_waybar_config '.height // 42')
    local current_margin_top=$(get_waybar_config '."margin-top" // 8')
    local current_margin_left=$(get_waybar_config '."margin-left" // 16')

    local dimension_options=(
        "📏 Height: $current_height"
        "⬆️ Top Margin: $current_margin_top"
        "⬅️ Left Margin: $current_margin_left"
        "➡️ Right Margin: $(get_waybar_config '."margin-right" // 16')"
    )

    local selected=$(printf '%s\n' "${dimension_options[@]}" | \
        rofi -dmenu -p "📐 Bar Dimensions" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📏 Height:"*)
            local new_height=$(echo "$current_height" | rofi -dmenu -p "Enter bar height:")
            if [[ "$new_height" =~ ^[0-9]+$ ]]; then
                set_waybar_config '.height' "$new_height"
                # Also update theme config
                if [[ -f "$THEME_CONFIG" ]]; then
                    local temp_file=$(mktemp)
                    jq ".components.waybar.height = $new_height" "$THEME_CONFIG" > "$temp_file" && mv "$temp_file" "$THEME_CONFIG"
                fi
            fi
            ;;
        "⬆️ Top Margin:"*)
            local new_margin=$(echo "$current_margin_top" | rofi -dmenu -p "Enter top margin:")
            if [[ "$new_margin" =~ ^[0-9]+$ ]]; then
                set_waybar_config '."margin-top"' "$new_margin"
            fi
            ;;
    esac
}

# Function to edit Waybar colors
edit_waybar_colors() {
    notify-send "🎨 Colors" "Waybar colors are managed by the central theme system" -t 3000

    if rofi -dmenu -p "Open theme editor?" <<< $'Yes\nNo' | grep -q "Yes"; then
        "$SCRIPT_DIR/scripts/theme-editor.sh" colors
    fi
}

# Function to apply all changes
apply_changes() {
    notify-send "🔄 Applying Changes" "Regenerating Waybar configuration..." -t 3000

    # Regenerate from theme
    if [[ -f "$SCRIPT_DIR/generators/apply-theme.py" ]]; then
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py
    fi

    # Restart Waybar
    restart_waybar
}

# Main Waybar editor menu
show_waybar_editor() {
    local main_menu=(
        "📊 Manage Modules"
        "🎨 Appearance & Styling"
        "⚙️ General Settings"
        "🔄 Apply Changes"
        "👁️ Preview Configuration"
        "💾 Save & Exit"
    )

    local selected=$(printf '%s\n' "${main_menu[@]}" | \
        rofi -dmenu -p "📊 Waybar Editor" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "📊 Manage Modules")
            manage_modules
            ;;
        "🎨 Appearance & Styling")
            manage_appearance
            ;;
        "⚙️ General Settings")
            edit_general_settings
            ;;
        "🔄 Apply Changes")
            apply_changes
            ;;
        "👁️ Preview Configuration")
            preview_waybar_config
            ;;
        "💾 Save & Exit")
            apply_changes
            return 0
            ;;
        *)
            return 0
            ;;
    esac

    # Return to main menu unless exiting
    show_waybar_editor
}

# Function to edit general settings
edit_general_settings() {
    local settings_menu=(
        "📍 Bar Position"
        "🖥️ Monitor Selection"
        "⏱️ Update Intervals"
        "🖱️ Mouse Interactions"
        "📐 Layer Settings"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${settings_menu[@]}" | \
        rofi -dmenu -p "⚙️ General Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📍 Bar Position")
            local positions=("top" "bottom")
            local current_position=$(get_waybar_config '.position // "top"')
            local new_position=$(printf '%s\n' "${positions[@]}" | \
                rofi -dmenu -p "Select bar position (current: $current_position):")
            if [[ -n "$new_position" ]]; then
                set_waybar_config '.position' "\"$new_position\""
            fi
            ;;
        "🖥️ Monitor Selection")
            local monitor=$(echo "0" | rofi -dmenu -p "Enter monitor number (0 for primary):")
            if [[ "$monitor" =~ ^[0-9]+$ ]]; then
                set_waybar_config '.output' "\"DP-$monitor\""
            fi
            ;;
    esac
}

# Function to preview Waybar config
preview_waybar_config() {
    local config_summary="Waybar Configuration Summary:

Height: $(get_waybar_config '.height')px
Position: $(get_waybar_config '.position')
Modules Left: $(get_waybar_config '."modules-left" | length') modules
Modules Center: $(get_waybar_config '."modules-center" | length') modules
Modules Right: $(get_waybar_config '."modules-right" | length') modules"

    echo "$config_summary" | rofi -dmenu -p "👁️ Waybar Preview" \
        -theme "$ROFI_THEME" -no-custom
}

# Main function
main() {
    if ! check_dependencies; then
        exit 1
    fi

    # Ensure Waybar config exists
    if [[ ! -f "$WAYBAR_CONFIG" ]]; then
        notify-send "❌ Config Missing" "Waybar configuration not found. Please run theme generator first." -t 5000
        exit 1
    fi

    case "${1:-menu}" in
        "menu")
            show_waybar_editor
            ;;
        "modules")
            manage_modules
            ;;
        "appearance")
            manage_appearance
            ;;
        "apply")
            apply_changes
            ;;
        *)
            echo "📊 Waybar Configuration Editor"
            echo ""
            echo "Usage: $0 {menu|modules|appearance|apply}"
            echo ""
            echo "Commands:"
            echo "  menu        - Show main Waybar editor menu"
            echo "  modules     - Manage Waybar modules"
            echo "  appearance  - Configure appearance and styling"
            echo "  apply       - Apply configuration changes"
            ;;
    esac
}

# Run main function
main "$@"
