#!/bin/bash
# ✨ Startup Effects and System Initialization
# Creates cyberpunk startup experience with smooth transitions

SCRIPT_DIR="$HOME/.config/hypr-system"
THEME_CONFIG="$SCRIPT_DIR/core/theme-config.json"

# Colors for effects
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"

# Function to show startup notification
show_startup_notification() {
    # Delay to ensure notification system is ready
    sleep 2

    notify-send "🗡️ SYSTEM INITIALIZED 🤖" \
        "Welcome to Cyberpunk Medieval Hyprland\n\nPress Super+H for hotkeys\nPress Super+T for themes\nPress Super+C for configuration" \
        -t 8000 \
        -u normal \
        -i dialog-information
}

# Function to initialize wallpaper system
init_wallpaper_system() {
    if [[ -f "$SCRIPT_DIR/scripts/wallpaper-cycle.sh" ]]; then
        "$SCRIPT_DIR/scripts/wallpaper-cycle.sh" init
    fi
}

# Function to perform system checks
system_health_check() {
    local issues=()

    # Check if theme config exists
    if [[ ! -f "$THEME_CONFIG" ]]; then
        issues+=("Theme configuration missing")
    fi

    # Check if scripts are executable
    if [[ ! -x "$SCRIPT_DIR/scripts/hotkey-display.sh" ]]; then
        issues+=("Hotkey display script not executable")
    fi

    # Check if waybar is running
    if ! pgrep -x "waybar" >/dev/null; then
        issues+=("Waybar not running")
    fi

    # Check if dunst is running
    if ! pgrep -x "dunst" >/dev/null; then
        issues+=("Dunst notification daemon not running")
    fi

    # Show issues if any
    if [[ ${#issues[@]} -gt 0 ]]; then
        local issue_text=$(printf '%s\n' "${issues[@]}")
        notify-send "⚠️ System Issues Detected" \
            "$issue_text\n\nRun configuration manager to fix" \
            -t 10000 \
            -u normal
    fi
}

# Function to setup dynamic wallpapers if enabled
setup_dynamic_wallpapers() {
    # Check if user wants dynamic wallpapers
    if [[ -f "$SCRIPT_DIR/.dynamic-wallpapers" ]]; then
        # Start wallpaper daemon for time-based changes
        (
            while true; do
                sleep 3600  # Check every hour
                if [[ -f "$SCRIPT_DIR/scripts/wallpaper-cycle.sh" ]]; then
                    "$SCRIPT_DIR/scripts/wallpaper-cycle.sh" time
                fi
            done
        ) &

        # Save PID for cleanup
        echo $! > "$SCRIPT_DIR/.wallpaper-daemon-pid"
    fi
}

# Function to initialize EWW widgets
init_eww_widgets() {
    if command -v eww >/dev/null 2>&1; then
        local eww_config="$HOME/.config/eww/hotkey-display/eww.yuck"

        if [[ -f "$eww_config" ]]; then
            # Initialize EWW daemon if not running
            if ! eww ping >/dev/null 2>&1; then
                eww daemon &
                sleep 2
            fi

            # Pre-load hotkey data
            cd "$HOME/.config/eww/hotkey-display" && eww update hotkey-visible=false
        fi
    fi
}

# Function to create welcome screen
show_welcome_screen() {
    if command -v eww >/dev/null 2>&1 && [[ -f "$HOME/.config/eww/welcome/eww.yuck" ]]; then
        # Show EWW welcome screen
        cd "$HOME/.config/eww/welcome" && eww open welcome-screen

        # Auto-close after 10 seconds
        (sleep 10 && eww close welcome-screen) &
    else
        # Fallback to notification
        show_startup_notification
    fi
}

# Function to optimize system for better performance
optimize_system() {
    # Set CPU governor to performance if available
    if [[ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]]; then
        echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
    fi

    # Increase file descriptor limits for better I/O
    ulimit -n 4096 2>/dev/null || true

    # Set nice priority for important processes
    if pgrep -x "waybar" >/dev/null; then
        sudo renice -10 $(pgrep waybar) 2>/dev/null || true
    fi
}

# Function to load user preferences
load_user_preferences() {
    local prefs_file="$SCRIPT_DIR/.user-preferences"

    if [[ -f "$prefs_file" ]]; then
        source "$prefs_file"

        # Apply preferences
        if [[ "$AUTO_THEME_SWITCH" == "true" ]]; then
            # Enable time-based theme switching
            echo "time-based" > "$SCRIPT_DIR/.theme-mode"
        fi

        if [[ "$DYNAMIC_WALLPAPERS" == "true" ]]; then
            touch "$SCRIPT_DIR/.dynamic-wallpapers"
        fi

        if [[ -n "$DEFAULT_WORKSPACE" ]]; then
            hyprctl dispatch workspace "$DEFAULT_WORKSPACE" 2>/dev/null || true
        fi
    fi
}

# Function to setup hotkey hints
setup_hotkey_hints() {
    # Create temporary hints file for first-time users
    local hints_file="$SCRIPT_DIR/.hotkey-hints"

    if [[ ! -f "$hints_file" ]]; then
        cat > "$hints_file" << 'EOF'
🗡️ QUICK START HOTKEYS 🤖

Essential Hotkeys:
Super + H     - Show all hotkeys
Super + T     - Theme manager
Super + C     - Configuration menu
Super + Space - Application launcher
Super + Enter - Terminal

Window Management:
Super + Q     - Close window
Super + F     - Fullscreen
Super + V     - Toggle floating

This hint will only show once.
EOF

        # Show hints in rofi
        if command -v rofi >/dev/null 2>&1; then
            (sleep 5 && cat "$hints_file" | rofi -dmenu -p "🗡️ Quick Start" -theme "$HOME/.config/rofi/themes/cyberpunk-medieval.rasi") &
        fi
    fi
}

# Function to check for updates
check_for_updates() {
    local last_check_file="$SCRIPT_DIR/.last-update-check"
    local current_date=$(date +%Y-%m-%d)

    # Check once per day
    if [[ ! -f "$last_check_file" ]] || [[ "$(cat "$last_check_file")" != "$current_date" ]]; then
        echo "$current_date" > "$last_check_file"

        # Background update check (non-blocking)
        (
            sleep 30  # Wait for system to settle
            if command -v git >/dev/null 2>&1 && [[ -d "$SCRIPT_DIR/.git" ]]; then
                cd "$SCRIPT_DIR"
                if git fetch --dry-run 2>/dev/null; then
                    local updates=$(git rev-list HEAD...origin/main --count 2>/dev/null || echo "0")
                    if [[ "$updates" -gt 0 ]]; then
                        notify-send "📦 Updates Available" \
                            "$updates updates available for Cyberpunk Medieval setup\n\nRun: git pull in $SCRIPT_DIR" \
                            -t 10000 \
                            -u normal
                    fi
                fi
            fi
        ) &
    fi
}

# Function to create session info
create_session_info() {
    local session_file="$SCRIPT_DIR/.current-session"

    cat > "$session_file" << EOF
# Hyprland Session Info
SESSION_START=$(date)
HYPR_VERSION=$(hyprctl version | head -1)
WAYBAR_PID=$(pgrep waybar || echo "not running")
DUNST_PID=$(pgrep dunst || echo "not running")
THEME=$(cat "$SCRIPT_DIR/.current-theme" 2>/dev/null || echo "default")
WALLPAPER=$(cat "$SCRIPT_DIR/.current-wallpaper" 2>/dev/null || echo "none")
EOF
}

# Main startup sequence
main() {
    # Set up logging
    exec 1> >(logger -t "hypr-startup")
    exec 2> >(logger -t "hypr-startup")

    echo "🚀 Starting Cyberpunk Medieval Hyprland initialization..."

    # Wait for essential services
    local wait_count=0
    while ! pgrep -x "waybar" >/dev/null && [[ $wait_count -lt 30 ]]; do
        sleep 1
        wait_count=$((wait_count + 1))
    done

    # Initialize components in order
    echo "📊 Creating session info..."
    create_session_info

    echo "🎨 Initializing wallpaper system..."
    init_wallpaper_system

    echo "🔧 Loading user preferences..."
    load_user_preferences

    echo "🎮 Initializing EWW widgets..."
    init_eww_widgets

    echo "⚡ Optimizing system..."
    optimize_system

    echo "🔍 Performing health check..."
    system_health_check

    echo "🖼️ Setting up dynamic wallpapers..."
    setup_dynamic_wallpapers

    echo "💡 Setting up hotkey hints..."
    setup_hotkey_hints

    echo "📦 Checking for updates..."
    check_for_updates

    echo "🎉 Showing welcome screen..."
    show_welcome_screen

    echo "✅ Cyberpunk Medieval Hyprland initialization complete!"

    # Create completion marker
    touch "$SCRIPT_DIR/.startup-complete"
}

# Handle command line arguments
case "${1:-start}" in
    "start")
        main
        ;;
    "health-check")
        system_health_check
        ;;
    "welcome")
        show_welcome_screen
        ;;
    "optimize")
        optimize_system
        ;;
    "check-updates")
        check_for_updates
        ;;
    *)
        echo "✨ Cyberpunk Medieval Startup Effects"
        echo ""
        echo "Usage: $0 {start|health-check|welcome|optimize|check-updates}"
        echo ""
        echo "Commands:"
        echo "  start        - Run full startup sequence (default)"
        echo "  health-check - Check system health only"
        echo "  welcome      - Show welcome screen"
        echo "  optimize     - Optimize system performance"
        echo "  check-updates- Check for updates"
        ;;
esac
