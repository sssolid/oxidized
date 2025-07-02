#!/bin/bash
# 🔧 System Settings Editor
# Comprehensive system-wide configuration management

SCRIPT_DIR="$HOME/.config/hypr-system"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"
CRIMSON="#dc143c"

# Function to check if running as root for system changes
check_root_access() {
    if [[ $EUID -eq 0 ]]; then
        notify-send "⚠️ Root Access" "Running with root privileges" -t 3000
        return 0
    else
        return 1
    fi
}

# Function to manage Hyprland settings
manage_hyprland_settings() {
    local hypr_menu=(
        "🖥️ Monitor Configuration"
        "🎮 Input Settings"
        "⚡ Performance Tuning"
        "🔧 Advanced Options"
        "🐛 Debug Settings"
        "← Back"
    )

    local selected=$(printf '%s\n' "${hypr_menu[@]}" | \
        rofi -dmenu -p "🔧 Hyprland Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🖥️ Monitor Configuration")
            configure_monitors
            ;;
        "🎮 Input Settings")
            configure_input
            ;;
        "⚡ Performance Tuning")
            performance_tuning
            ;;
        "🔧 Advanced Options")
            advanced_hyprland_options
            ;;
        "🐛 Debug Settings")
            debug_settings
            ;;
    esac
}

# Function to configure monitors
configure_monitors() {
    local monitor_options=(
        "🖥️ Auto-detect Monitors"
        "📐 Set Resolution"
        "🔄 Set Refresh Rate"
        "📍 Set Position"
        "🔍 Scale Factor"
        "🔄 Rotation"
        "👁️ View Current Setup"
        "📝 Edit Monitor Config File"
        "← Back"
    )

    local selected=$(printf '%s\n' "${monitor_options[@]}" | \
        rofi -dmenu -p "🖥️ Monitor Configuration" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🖥️ Auto-detect Monitors")
            auto_detect_monitors
            ;;
        "📐 Set Resolution")
            set_monitor_resolution
            ;;
        "👁️ View Current Setup")
            view_monitor_setup
            ;;
        "📝 Edit Monitor Config File")
            edit_monitor_config_file
            ;;
    esac
}

# Function to auto-detect monitors
auto_detect_monitors() {
    notify-send "🖥️ Detecting Monitors" "Scanning for connected displays..." -t 3000

    # Get connected monitors
    local monitors=($(hyprctl monitors -j | jq -r '.[].name' 2>/dev/null))

    if [[ ${#monitors[@]} -eq 0 ]]; then
        notify-send "❌ No Monitors" "No monitors detected" -t 3000
        return 1
    fi

    local monitor_info=""
    for monitor in "${monitors[@]}"; do
        local info=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$monitor\") | \"\(.width)x\(.height)@\(.refreshRate)Hz\"" 2>/dev/null)
        monitor_info="$monitor_info$monitor: $info\n"
    done

    echo -e "Connected Monitors:\n$monitor_info" | \
        rofi -dmenu -p "🖥️ Detected Monitors" \
        -theme "$ROFI_THEME" -no-custom
}

# Function to view monitor setup
view_monitor_setup() {
    local monitor_info=$(hyprctl monitors)
    echo "$monitor_info" | rofi -dmenu -p "👁️ Current Monitor Setup" \
        -theme "$ROFI_THEME" -no-custom -width 80
}

# Function to edit monitor config file
edit_monitor_config_file() {
    local monitor_config="$HOME/.config/hypr/configs/monitors.conf"

    if [[ -f "$monitor_config" ]]; then
        if command -v code >/dev/null 2>&1; then
            code "$monitor_config" &
        elif command -v nano >/dev/null 2>&1; then
            kitty -e nano "$monitor_config" &
        else
            notify-send "❌ No Editor" "Please install code or nano" -t 3000
        fi
    else
        notify-send "❌ Config Missing" "Monitor config file not found" -t 3000
    fi
}

# Function to configure input settings
configure_input() {
    local input_options=(
        "⌨️ Keyboard Settings"
        "🖱️ Mouse Settings"
        "📱 Touchpad Settings"
        "🎮 Gamepad Settings"
        "🌐 Input Method"
        "← Back"
    )

    local selected=$(printf '%s\n' "${input_options[@]}" | \
        rofi -dmenu -p "🎮 Input Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "⌨️ Keyboard Settings")
            configure_keyboard
            ;;
        "🖱️ Mouse Settings")
            configure_mouse
            ;;
        "📱 Touchpad Settings")
            configure_touchpad
            ;;
        "🎮 Gamepad Settings")
            configure_gamepad
            ;;
        "🌐 Input Method")
            configure_input_method
            ;;
    esac
}

# Function to configure keyboard
configure_keyboard() {
    local kb_options=(
        "🌐 Keyboard Layout"
        "🔁 Repeat Rate"
        "⏱️ Repeat Delay"
        "💡 NumLock on Start"
        "← Back"
    )

    local selected=$(printf '%s\n' "${kb_options[@]}" | \
        rofi -dmenu -p "⌨️ Keyboard Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🌐 Keyboard Layout")
            local layouts=("us" "us-intl" "gb" "de" "fr" "es" "it" "ru" "jp")
            local current_layout=$(hyprctl getoption input:kb_layout | grep -o '".*"' | tr -d '"' 2>/dev/null || echo "us")
            local new_layout=$(printf '%s\n' "${layouts[@]}" | \
                rofi -dmenu -p "Select layout (current: $current_layout):")
            if [[ -n "$new_layout" ]]; then
                hyprctl keyword input:kb_layout "$new_layout"
                notify-send "⌨️ Layout Changed" "Keyboard layout set to $new_layout" -t 3000
            fi
            ;;
        "🔁 Repeat Rate")
            local rate=$(echo "25" | rofi -dmenu -p "Enter repeat rate (chars/sec):")
            if [[ "$rate" =~ ^[0-9]+$ ]]; then
                hyprctl keyword input:repeat_rate "$rate"
                notify-send "🔁 Repeat Rate" "Set to $rate chars/sec" -t 3000
            fi
            ;;
        "⏱️ Repeat Delay")
            local delay=$(echo "600" | rofi -dmenu -p "Enter repeat delay (ms):")
            if [[ "$delay" =~ ^[0-9]+$ ]]; then
                hyprctl keyword input:repeat_delay "$delay"
                notify-send "⏱️ Repeat Delay" "Set to ${delay}ms" -t 3000
            fi
            ;;
    esac
}

# Function to configure mouse
configure_mouse() {
    local mouse_options=(
        "🐭 Mouse Sensitivity"
        "🔄 Mouse Acceleration"
        "👆 Left/Right Handed"
        "🎯 Follow Mouse Focus"
        "← Back"
    )

    local selected=$(printf '%s\n' "${mouse_options[@]}" | \
        rofi -dmenu -p "🖱️ Mouse Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🐭 Mouse Sensitivity")
            local sensitivity=$(echo "0" | rofi -dmenu -p "Enter sensitivity (-1.0 to 1.0):")
            if [[ "$sensitivity" =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
                hyprctl keyword input:sensitivity "$sensitivity"
                notify-send "🐭 Sensitivity" "Set to $sensitivity" -t 3000
            fi
            ;;
        "🎯 Follow Mouse Focus")
            local follow=$(rofi -dmenu -p "Follow mouse focus?" <<< $'0 - Disabled\n1 - Loose\n2 - Strict')
            if [[ "$follow" =~ ^[0-2]$ ]]; then
                hyprctl keyword input:follow_mouse "$follow"
                notify-send "🎯 Follow Mouse" "Set to level $follow" -t 3000
            fi
            ;;
    esac
}

# Function to configure touchpad
configure_touchpad() {
    local touchpad_options=(
        "📱 Natural Scroll"
        "👆 Tap to Click"
        "✌️ Two-finger Scroll"
        "👆 Disable While Typing"
        "← Back"
    )

    local selected=$(printf '%s\n' "${touchpad_options[@]}" | \
        rofi -dmenu -p "📱 Touchpad Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📱 Natural Scroll")
            local natural=$(rofi -dmenu -p "Enable natural scroll?" <<< $'true\nfalse')
            hyprctl keyword input:touchpad:natural_scroll "$natural"
            notify-send "📱 Natural Scroll" "Set to $natural" -t 3000
            ;;
        "👆 Tap to Click")
            local tap=$(rofi -dmenu -p "Enable tap to click?" <<< $'true\nfalse')
            hyprctl keyword input:touchpad:tap-to-click "$tap"
            notify-send "👆 Tap to Click" "Set to $tap" -t 3000
            ;;
        "👆 Disable While Typing")
            local disable=$(rofi -dmenu -p "Disable while typing?" <<< $'true\nfalse')
            hyprctl keyword input:touchpad:disable_while_typing "$disable"
            notify-send "👆 Disable While Typing" "Set to $disable" -t 3000
            ;;
    esac
}

# Function to manage system services
manage_services() {
    local service_menu=(
        "👁️ View Running Services"
        "▶️ Start Service"
        "⏹️ Stop Service"
        "🔄 Restart Service"
        "✅ Enable Service"
        "❌ Disable Service"
        "📊 Service Status"
        "← Back"
    )

    local selected=$(printf '%s\n' "${service_menu[@]}" | \
        rofi -dmenu -p "🔧 System Services" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "👁️ View Running Services")
            view_running_services
            ;;
        "▶️ Start Service")
            start_service
            ;;
        "⏹️ Stop Service")
            stop_service
            ;;
        "🔄 Restart Service")
            restart_service
            ;;
        "✅ Enable Service")
            enable_service
            ;;
        "❌ Disable Service")
            disable_service
            ;;
        "📊 Service Status")
            check_service_status
            ;;
    esac
}

# Function to view running services
view_running_services() {
    local services=$(systemctl --user list-units --type=service --state=running --no-legend | awk '{print $1}' | head -20)

    if [[ -z "$services" ]]; then
        notify-send "📊 No Services" "No user services running" -t 3000
        return
    fi

    echo "$services" | rofi -dmenu -p "👁️ Running Services" \
        -theme "$ROFI_THEME" -no-custom
}

# Function to start service
start_service() {
    local service=$(echo "" | rofi -dmenu -p "Enter service name to start:")
    if [[ -n "$service" ]]; then
        if systemctl --user start "$service" 2>/dev/null; then
            notify-send "▶️ Service Started" "Started $service" -t 3000
        else
            # Try system service
            if sudo systemctl start "$service" 2>/dev/null; then
                notify-send "▶️ Service Started" "Started system service $service" -t 3000
            else
                notify-send "❌ Start Failed" "Could not start $service" -t 3000
            fi
        fi
    fi
}

# Function to manage environment variables
manage_environment() {
    local env_menu=(
        "👁️ View Current Environment"
        "➕ Add Environment Variable"
        "✏️ Edit Environment Variable"
        "🗑️ Remove Environment Variable"
        "📄 Edit Environment File"
        "← Back"
    )

    local selected=$(printf '%s\n' "${env_menu[@]}" | \
        rofi -dmenu -p "🌍 Environment Variables" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "👁️ View Current Environment")
            view_environment
            ;;
        "➕ Add Environment Variable")
            add_environment_variable
            ;;
        "✏️ Edit Environment Variable")
            edit_environment_variable
            ;;
        "🗑️ Remove Environment Variable")
            remove_environment_variable
            ;;
        "📄 Edit Environment File")
            edit_environment_file
            ;;
    esac
}

# Function to view environment
view_environment() {
    local relevant_vars=$(env | grep -E "(XDG_|QT_|GTK_|WAYLAND|HYPR)" | sort)

    echo "$relevant_vars" | rofi -dmenu -p "🌍 Environment Variables" \
        -theme "$ROFI_THEME" -no-custom -width 80
}

# Function to add environment variable
add_environment_variable() {
    local var_name=$(echo "" | rofi -dmenu -p "Enter variable name:")
    if [[ -z "$var_name" ]]; then
        return 1
    fi

    local var_value=$(echo "" | rofi -dmenu -p "Enter variable value:")
    if [[ -z "$var_value" ]]; then
        return 1
    fi

    # Add to environment config
    local env_config="$HOME/.config/hypr/configs/environment.conf"
    if [[ -f "$env_config" ]]; then
        echo "env = $var_name,$var_value" >> "$env_config"
        notify-send "✅ Variable Added" "$var_name=$var_value added to environment" -t 3000

        if rofi -dmenu -p "Reload Hyprland to apply?" <<< $'Yes\nNo' | grep -q "Yes"; then
            hyprctl reload
        fi
    else
        notify-send "❌ Config Missing" "Environment config file not found" -t 3000
    fi
}

# Function to manage startup applications
manage_startup() {
    local startup_menu=(
        "👁️ View Startup Applications"
        "➕ Add Startup Application"
        "🗑️ Remove Startup Application"
        "✏️ Edit Startup Application"
        "📄 Edit Autostart File"
        "🔄 Test Startup Application"
        "← Back"
    )

    local selected=$(printf '%s\n' "${startup_menu[@]}" | \
        rofi -dmenu -p "🚀 Startup Applications" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "👁️ View Startup Applications")
            view_startup_applications
            ;;
        "➕ Add Startup Application")
            add_startup_application
            ;;
        "🗑️ Remove Startup Application")
            remove_startup_application
            ;;
        "📄 Edit Autostart File")
            edit_autostart_file
            ;;
        "🔄 Test Startup Application")
            test_startup_application
            ;;
    esac
}

# Function to view startup applications
view_startup_applications() {
    local autostart_file="$HOME/.config/hypr/configs/autostart.conf"

    if [[ -f "$autostart_file" ]]; then
        local startup_apps=$(grep "^exec-once" "$autostart_file" | sed 's/exec-once = //')

        if [[ -n "$startup_apps" ]]; then
            echo "$startup_apps" | rofi -dmenu -p "🚀 Startup Applications" \
                -theme "$ROFI_THEME" -no-custom -width 80
        else
            notify-send "📋 No Startup Apps" "No startup applications configured" -t 3000
        fi
    else
        notify-send "❌ Config Missing" "Autostart config file not found" -t 3000
    fi
}

# Function to add startup application
add_startup_application() {
    local app_command=$(echo "" | rofi -dmenu -p "Enter application command:")
    if [[ -z "$app_command" ]]; then
        return 1
    fi

    local autostart_file="$HOME/.config/hypr/configs/autostart.conf"
    if [[ -f "$autostart_file" ]]; then
        echo "exec-once = $app_command" >> "$autostart_file"
        notify-send "✅ Startup App Added" "$app_command added to startup" -t 3000
    else
        notify-send "❌ Config Missing" "Autostart config file not found" -t 3000
    fi
}

# Function to manage power settings
manage_power() {
    local power_menu=(
        "💻 Laptop Power Settings"
        "🖥️ Display Power Management"
        "⏰ Idle Actions"
        "🔋 Battery Thresholds"
        "🎛️ CPU Governor"
        "❄️ Thermal Management"
        "← Back"
    )

    local selected=$(printf '%s\n' "${power_menu[@]}" | \
        rofi -dmenu -p "⚡ Power Management" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "💻 Laptop Power Settings")
            configure_laptop_power
            ;;
        "🖥️ Display Power Management")
            configure_display_power
            ;;
        "⏰ Idle Actions")
            configure_idle_actions
            ;;
        "🎛️ CPU Governor")
            configure_cpu_governor
            ;;
    esac
}

# Function to configure CPU governor
configure_cpu_governor() {
    if [[ ! -d "/sys/devices/system/cpu/cpu0/cpufreq" ]]; then
        notify-send "❌ Not Supported" "CPU frequency scaling not available" -t 3000
        return 1
    fi

    local available_governors=($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null))
    local current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

    local selected_governor=$(printf '%s\n' "${available_governors[@]}" | \
        rofi -dmenu -p "🎛️ CPU Governor (current: $current_governor):" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected_governor" ]]; then
        if echo "$selected_governor" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null; then
            notify-send "🎛️ Governor Changed" "CPU governor set to $selected_governor" -t 3000
        else
            notify-send "❌ Failed" "Could not change CPU governor" -t 3000
        fi
    fi
}

# Function to configure display power
configure_display_power() {
    local dpms_options=(
        "🖥️ Enable DPMS"
        "⏰ Set Standby Time"
        "😴 Set Suspend Time"
        "⚫ Set Off Time"
        "← Back"
    )

    local selected=$(printf '%s\n' "${dpms_options[@]}" | \
        rofi -dmenu -p "🖥️ Display Power" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "⏰ Set Standby Time")
            local standby_time=$(echo "600" | rofi -dmenu -p "Enter standby time (seconds):")
            if [[ "$standby_time" =~ ^[0-9]+$ ]]; then
                hyprctl keyword misc:key_press_enables_dpms true
                notify-send "⏰ Standby Time" "Set to ${standby_time}s" -t 3000
            fi
            ;;
    esac
}

# Function to show system information
show_system_info() {
    local system_info="🖥️ SYSTEM INFORMATION

$(hostnamectl 2>/dev/null | head -8)

🐧 KERNEL: $(uname -r)
💾 MEMORY: $(free -h | awk 'NR==2{printf "%.1f/%.1fGB (%.0f%%)", $3/1024/1024/1024, $2/1024/1024/1024, $3*100/$2}')
💽 STORAGE: $(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')
⚡ UPTIME: $(uptime -p)

🎮 HYPRLAND: $(hyprctl version | head -1)
📊 WAYBAR: $(waybar --version 2>/dev/null || echo "Not running")

🌡️ TEMPERATURE: $(sensors 2>/dev/null | grep 'Core 0' | awk '{print $3}' || echo "N/A")"

    echo "$system_info" | rofi -dmenu -p "ℹ️ System Information" \
        -theme "$ROFI_THEME" -no-custom -width 60
}

# Main system editor menu
show_system_editor() {
    local main_menu=(
        "🔧 Hyprland Settings"
        "🔌 System Services"
        "🌍 Environment Variables"
        "🚀 Startup Applications"
        "⚡ Power Management"
        "ℹ️ System Information"
        "🛠️ Advanced System Tools"
        "💾 Save & Exit"
    )

    local selected=$(printf '%s\n' "${main_menu[@]}" | \
        rofi -dmenu -p "🔧 System Settings Editor" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "🔧 Hyprland Settings")
            manage_hyprland_settings
            ;;
        "🔌 System Services")
            manage_services
            ;;
        "🌍 Environment Variables")
            manage_environment
            ;;
        "🚀 Startup Applications")
            manage_startup
            ;;
        "⚡ Power Management")
            manage_power
            ;;
        "ℹ️ System Information")
            show_system_info
            ;;
        "🛠️ Advanced System Tools")
            show_advanced_tools
            ;;
        "💾 Save & Exit")
            apply_system_changes
            return 0
            ;;
        *)
            return 0
            ;;
    esac

    # Return to main menu unless exiting
    show_system_editor
}

# Function to show advanced tools
show_advanced_tools() {
    local advanced_menu=(
        "🔍 Process Manager"
        "🌐 Network Configuration"
        "🔐 Security Settings"
        "📦 Package Management"
        "🧹 System Cleanup"
        "📊 Performance Monitor"
        "← Back"
    )

    local selected=$(printf '%s\n' "${advanced_menu[@]}" | \
        rofi -dmenu -p "🛠️ Advanced Tools" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🔍 Process Manager")
            if command -v htop >/dev/null 2>&1; then
                kitty -e htop &
            else
                kitty -e top &
            fi
            ;;
        "📦 Package Management")
            show_package_manager
            ;;
        "🧹 System Cleanup")
            system_cleanup
            ;;
        "📊 Performance Monitor")
            kitty -e "watch -n 1 'echo \"CPU Usage:\"; grep \"cpu \" /proc/stat | awk \"{printf \"%.2f%%\", (\$2+\$4)*100/(\$2+\$3+\$4+\$5)}\" && echo && echo \"Memory Usage:\" && free -h && echo && echo \"Disk Usage:\" && df -h /'"
            ;;
    esac
}

# Function to show package manager
show_package_manager() {
    local pkg_managers=()

    if command -v pacman >/dev/null 2>&1; then
        pkg_managers+=("🎯 Arch Package Manager")
    fi
    if command -v apt >/dev/null 2>&1; then
        pkg_managers+=("📦 Debian Package Manager")
    fi
    if command -v dnf >/dev/null 2>&1; then
        pkg_managers+=("🔴 Fedora Package Manager")
    fi

    pkg_managers+=("← Back")

    local selected=$(printf '%s\n' "${pkg_managers[@]}" | \
        rofi -dmenu -p "📦 Package Management" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🎯 Arch Package Manager")
            kitty -e "sudo pacman -Syu" &
            ;;
        "📦 Debian Package Manager")
            kitty -e "sudo apt update && sudo apt upgrade" &
            ;;
        "🔴 Fedora Package Manager")
            kitty -e "sudo dnf update" &
            ;;
    esac
}

# Function to apply system changes
apply_system_changes() {
    notify-send "🔄 Applying Changes" "Reloading system configuration..." -t 3000

    # Reload Hyprland config
    hyprctl reload 2>/dev/null

    # Restart user services if needed
    systemctl --user daemon-reload

    notify-send "✅ Changes Applied" "System configuration updated" -t 3000
}

# Function to perform system cleanup
system_cleanup() {
    local cleanup_options=(
        "🗑️ Clear Package Cache"
        "🧹 Clean Temporary Files"
        "📋 Clear Clipboard History"
        "🖼️ Remove Broken Wallpaper Links"
        "📊 Clean Journal Logs"
        "← Back"
    )

    local selected=$(printf '%s\n' "${cleanup_options[@]}" | \
        rofi -dmenu -p "🧹 System Cleanup" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🗑️ Clear Package Cache")
            if command -v pacman >/dev/null 2>&1; then
                sudo pacman -Sc --noconfirm
                notify-send "🗑️ Cache Cleared" "Package cache cleaned" -t 3000
            fi
            ;;
        "🧹 Clean Temporary Files")
            sudo rm -rf /tmp/* 2>/dev/null
            rm -rf ~/.cache/thumbnails/* 2>/dev/null
            notify-send "🧹 Temp Cleaned" "Temporary files removed" -t 3000
            ;;
        "📊 Clean Journal Logs")
            sudo journalctl --vacuum-time=7d
            notify-send "📊 Logs Cleaned" "Old journal logs removed" -t 3000
            ;;
    esac
}

# Main function
main() {
    case "${1:-menu}" in
        "menu")
            show_system_editor
            ;;
        "hyprland")
            manage_hyprland_settings
            ;;
        "services")
            manage_services
            ;;
        "environment")
            manage_environment
            ;;
        "startup")
            manage_startup
            ;;
        "power")
            manage_power
            ;;
        "info")
            show_system_info
            ;;
        *)
            echo "🔧 System Settings Editor"
            echo ""
            echo "Usage: $0 {menu|hyprland|services|environment|startup|power|info}"
            echo ""
            echo "Commands:"
            echo "  menu         - Show main system editor menu"
            echo "  hyprland     - Configure Hyprland settings"
            echo "  services     - Manage system services"
            echo "  environment  - Edit environment variables"
            echo "  startup      - Manage startup applications"
            echo "  power        - Configure power management"
            echo "  info         - Show system information"
            ;;
    esac
}

# Run main function
main "$@"
