#!/bin/bash
# ⚡ Cyberpunk Medieval Power Menu
# Elegant power management with confirmation dialogs

ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"
SCRIPT_DIR="$HOME/.config/hypr-system"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
CRIMSON="#dc143c"
GREEN="#39ff14"

# Function to show confirmation dialog
confirm_action() {
    local action="$1"
    local message="$2"
    local icon="$3"

    local options=("✅ Yes" "❌ No")

    local selected=$(printf '%s\n' "${options[@]}" | \
        rofi -dmenu \
        -p "$icon $message" \
        -theme "$ROFI_THEME" \
        -markup-rows \
        -width 30 \
        -lines 2)

    [[ "$selected" == "✅ Yes" ]]
}

# Function to save session state
save_session_state() {
    local state_file="$SCRIPT_DIR/.session-state"

    {
        echo "# Session state saved on $(date)"
        echo "CURRENT_THEME=$(cat "$SCRIPT_DIR/.current-theme" 2>/dev/null || echo "default")"
        echo "CURRENT_WALLPAPER=$(cat "$SCRIPT_DIR/.current-wallpaper" 2>/dev/null || echo "")"
        echo "OPEN_WINDOWS=$(hyprctl clients -j | jq -r '.[].class' | sort | uniq -c)"
        echo "CURRENT_WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id')"
        echo "UPTIME=$(uptime -p)"
    } > "$state_file"
}

# Function to cleanup before shutdown/reboot
cleanup_session() {
    echo "🧹 Cleaning up session..."

    # Save session state
    save_session_state

    # Stop wallpaper daemon if running
    if [[ -f "$SCRIPT_DIR/.wallpaper-daemon-pid" ]]; then
        local daemon_pid=$(cat "$SCRIPT_DIR/.wallpaper-daemon-pid")
        kill "$daemon_pid" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/.wallpaper-daemon-pid"
    fi

    # Close EWW widgets gracefully
    if command -v eww >/dev/null 2>&1; then
        eww close-all 2>/dev/null || true
        eww kill 2>/dev/null || true
    fi

    # Backup current configuration
    if [[ -f "$SCRIPT_DIR/core/theme-config.json" ]]; then
        cp "$SCRIPT_DIR/core/theme-config.json" "$SCRIPT_DIR/backups/theme-backup-$(date +%Y%m%d_%H%M%S).json" 2>/dev/null || true
    fi

    echo "✅ Session cleanup complete"
}

# Function to show power options
show_power_menu() {
    local power_options=(
        "🔌 Shutdown|Shutdown the system|shutdown"
        "🔄 Reboot|Restart the system|reboot"
        "🌙 Suspend|Suspend to RAM|suspend"
        "😴 Hibernate|Hibernate to disk|hibernate"
        "🔒 Lock Screen|Lock the current session|lock"
        "🚪 Logout|End Hyprland session|logout"
        "🔄 Reload Hyprland|Restart Hyprland compositor|reload"
        "⚠️ Kill Hyprland|Force kill Hyprland|kill"
    )

    # Prepare menu display
    local menu_items=()
    local actions=()
    local descriptions=()

    for option in "${power_options[@]}"; do
        IFS='|' read -r display description action <<< "$option"
        menu_items+=("$display")
        actions+=("$action")
        descriptions+=("$description")
    done

    # Show menu
    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu \
        -p "⚡ Power Menu" \
        -theme "$ROFI_THEME" \
        -markup-rows \
        -width 40 \
        -lines 8)

    # Find selected action
    for i in "${!menu_items[@]}"; do
        if [[ "${menu_items[$i]}" == "$selected" ]]; then
            local action="${actions[$i]}"
            local description="${descriptions[$i]}"
            execute_power_action "$action" "$description"
            break
        fi
    done
}

# Function to execute power actions
execute_power_action() {
    local action="$1"
    local description="$2"

    case "$action" in
        "shutdown")
            if confirm_action "shutdown" "Shutdown the system?" "🔌"; then
                notify-send "🔌 Shutting Down" "System will shutdown in 5 seconds..." -t 5000 -u critical
                cleanup_session
                sleep 5
                systemctl poweroff
            fi
            ;;
        "reboot")
            if confirm_action "reboot" "Restart the system?" "🔄"; then
                notify-send "🔄 Rebooting" "System will restart in 5 seconds..." -t 5000 -u critical
                cleanup_session
                sleep 5
                systemctl reboot
            fi
            ;;
        "suspend")
            if confirm_action "suspend" "Suspend to RAM?" "🌙"; then
                notify-send "🌙 Suspending" "System going to sleep..." -t 3000 -u normal

                # Lock screen before suspend
                if command -v swaylock >/dev/null 2>&1; then
                    swaylock &
                    sleep 1
                fi

                systemctl suspend
            fi
            ;;
        "hibernate")
            if confirm_action "hibernate" "Hibernate to disk?" "😴"; then
                notify-send "😴 Hibernating" "System hibernating..." -t 3000 -u normal
                cleanup_session

                # Lock screen before hibernate
                if command -v swaylock >/dev/null 2>&1; then
                    swaylock &
                    sleep 1
                fi

                systemctl hibernate
            fi
            ;;
        "lock")
            if command -v swaylock >/dev/null 2>&1; then
                notify-send "🔒 Locking Screen" "Screen locked" -t 2000 -u normal
                swaylock
            elif command -v hyprlock >/dev/null 2>&1; then
                notify-send "🔒 Locking Screen" "Screen locked" -t 2000 -u normal
                hyprlock
            else
                notify-send "❌ Lock Error" "No screen locker found" -t 5000 -u critical
            fi
            ;;
        "logout")
            if confirm_action "logout" "End Hyprland session?" "🚪"; then
                notify-send "🚪 Logging Out" "Ending session..." -t 3000 -u normal
                cleanup_session
                sleep 2
                hyprctl dispatch exit
            fi
            ;;
        "reload")
            if confirm_action "reload" "Reload Hyprland compositor?" "🔄"; then
                notify-send "🔄 Reloading Hyprland" "Restarting compositor..." -t 3000 -u normal
                hyprctl reload

                # Restart waybar and dunst
                sleep 2
                pkill waybar && waybar &
                pkill dunst && dunst &

                notify-send "✅ Reload Complete" "Hyprland reloaded successfully" -t 3000 -u normal
            fi
            ;;
        "kill")
            if confirm_action "kill" "Force kill Hyprland? (Unsafe!)" "⚠️"; then
                notify-send "⚠️ Force Killing Hyprland" "This may cause data loss!" -t 5000 -u critical
                sleep 3
                pkill -KILL Hyprland
            fi
            ;;
        *)
            notify-send "❌ Unknown Action" "Action '$action' not recognized" -t 3000 -u critical
            ;;
    esac
}

# Function to show system info
show_system_info() {
    local uptime=$(uptime -p)
    local load=$(uptime | awk -F'load average:' '{print $2}')
    local memory=$(free -h | awk 'NR==2{printf "%.1f/%.1fGB (%.0f%%)", $3/1024/1024/1024, $2/1024/1024/1024, $3*100/$2}')
    local disk=$(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')
    local session_uptime=""

    if [[ -f "$SCRIPT_DIR/.current-session" ]]; then
        local session_start=$(grep "SESSION_START" "$SCRIPT_DIR/.current-session" | cut -d'=' -f2-)
        session_uptime="Session: $(date -d "$session_start" +'%H:%M on %d/%m')"
    fi

    local info_text="System: $uptime
$session_uptime
Load:$load
Memory: $memory
Disk: $disk

Hyprland: $(hyprctl version | head -1 | awk '{print $2}')"

    echo "$info_text" | rofi -dmenu -p "💻 System Info" -theme "$ROFI_THEME" -markup-rows -no-custom -width 50
}

# Function to show battery info (if laptop)
show_battery_info() {
    local battery_path="/sys/class/power_supply/BAT0"

    if [[ -d "$battery_path" ]]; then
        local capacity=$(cat "$battery_path/capacity" 2>/dev/null || echo "Unknown")
        local status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
        local health=""

        if [[ -f "$battery_path/health" ]]; then
            health="Health: $(cat "$battery_path/health")"
        fi

        local battery_text="Battery: $capacity% ($status)
$health

🔋 Power Management:
- Use suspend for short breaks
- Use hibernate for longer periods
- Avoid deep discharge"

        echo "$battery_text" | rofi -dmenu -p "🔋 Battery Info" -theme "$ROFI_THEME" -markup-rows -no-custom -width 40
    else
        notify-send "🔋 Battery Info" "No battery detected (desktop system)" -t 3000 -u normal
    fi
}

# Function to show advanced options
show_advanced_menu() {
    local advanced_options=(
        "💻 System Info|Show system information|info"
        "🔋 Battery Info|Show battery status|battery"
        "📊 Resource Monitor|Open system monitor|monitor"
        "🔧 Service Manager|Manage system services|services"
        "📂 Session State|View current session info|session"
        "🧹 Cleanup System|Clean temporary files|cleanup"
        "⚙️ Power Settings|Configure power management|settings"
    )

    local menu_items=()
    local actions=()

    for option in "${advanced_options[@]}"; do
        IFS='|' read -r display description action <<< "$option"
        menu_items+=("$display")
        actions+=("$action")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu \
        -p "🔧 Advanced Options" \
        -theme "$ROFI_THEME" \
        -markup-rows \
        -width 40)

    for i in "${!menu_items[@]}"; do
        if [[ "${menu_items[$i]}" == "$selected" ]]; then
            local action="${actions[$i]}"
            case "$action" in
                "info")
                    show_system_info
                    ;;
                "battery")
                    show_battery_info
                    ;;
                "monitor")
                    if command -v htop >/dev/null 2>&1; then
                        kitty -e htop &
                    elif command -v top >/dev/null 2>&1; then
                        kitty -e top &
                    else
                        notify-send "❌ Monitor" "No system monitor found" -t 3000
                    fi
                    ;;
                "services")
                    kitty -e sudo systemctl --type=service &
                    ;;
                "session")
                    if [[ -f "$SCRIPT_DIR/.current-session" ]]; then
                        cat "$SCRIPT_DIR/.current-session" | rofi -dmenu -p "📂 Session State" -theme "$ROFI_THEME" -no-custom -width 60
                    else
                        notify-send "📂 Session State" "No session state file found" -t 3000
                    fi
                    ;;
                "cleanup")
                    if confirm_action "cleanup" "Clean temporary files?" "🧹"; then
                        notify-send "🧹 Cleaning System" "Removing temporary files..." -t 3000
                        # Clean common temp locations
                        rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
                        rm -rf /tmp/* 2>/dev/null || true
                        # Clean old logs
                        sudo journalctl --vacuum-time=7d 2>/dev/null || true
                        notify-send "✅ Cleanup Complete" "System cleaned successfully" -t 3000
                    fi
                    ;;
                "settings")
                    if command -v gnome-control-center >/dev/null 2>&1; then
                        gnome-control-center power &
                    else
                        notify-send "⚙️ Power Settings" "Open your system settings manually" -t 3000
                    fi
                    ;;
            esac
            break
        fi
    done
}

# Main menu function
main() {
    case "${1:-menu}" in
        "menu")
            show_power_menu
            ;;
        "shutdown")
            execute_power_action "shutdown" "Shutdown the system"
            ;;
        "reboot")
            execute_power_action "reboot" "Restart the system"
            ;;
        "suspend")
            execute_power_action "suspend" "Suspend to RAM"
            ;;
        "hibernate")
            execute_power_action "hibernate" "Hibernate to disk"
            ;;
        "lock")
            execute_power_action "lock" "Lock screen"
            ;;
        "logout")
            execute_power_action "logout" "End session"
            ;;
        "reload")
            execute_power_action "reload" "Reload Hyprland"
            ;;
        "info")
            show_system_info
            ;;
        "advanced")
            show_advanced_menu
            ;;
        *)
            echo "⚡ Cyberpunk Medieval Power Menu"
            echo ""
            echo "Usage: $0 {menu|shutdown|reboot|suspend|hibernate|lock|logout|reload|info|advanced}"
            echo ""
            echo "Commands:"
            echo "  menu      - Show power menu (default)"
            echo "  shutdown  - Shutdown system"
            echo "  reboot    - Restart system"
            echo "  suspend   - Suspend to RAM"
            echo "  hibernate - Hibernate to disk"
            echo "  lock      - Lock screen"
            echo "  logout    - End Hyprland session"
            echo "  reload    - Reload Hyprland"
            echo "  info      - Show system info"
            echo "  advanced  - Advanced options"
            ;;
    esac
}

# Run main function
main "$@"
