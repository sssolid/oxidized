#!/bin/bash
# 🎨 Theme Startup Manager
# Handles theme initialization and application at startup

SCRIPT_DIR="$HOME/.config/hypr-system"
THEME_CONFIG="$SCRIPT_DIR/core/theme-config.json"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"

# Function to get current theme
get_current_theme() {
    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        cat "$SCRIPT_DIR/.current-theme"
    else
        echo "cyberpunk-medieval"
    fi
}

# Function to apply theme at startup
apply_startup_theme() {
    local theme_name=$(get_current_theme)

    echo "🎨 Applying theme at startup: $theme_name"

    # Check if theme config exists
    if [[ ! -f "$THEME_CONFIG" ]]; then
        echo "⚠️ Theme config not found, generating default..."
        generate_default_theme
    fi

    # Apply theme using the generator
    if [[ -f "$SCRIPT_DIR/generators/apply-theme.py" ]]; then
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py
        echo "✅ Theme applied successfully"
    else
        echo "❌ Theme generator not found"
        return 1
    fi
}

# Function to generate default theme if missing
generate_default_theme() {
    cat > "$THEME_CONFIG" << 'EOF'
{
  "meta": {
    "name": "Cyberpunk Medieval",
    "version": "2.0",
    "author": "System",
    "description": "Default cyberpunk theme with medieval touches"
  },
  "colors": {
    "primary": {
      "bg_primary": "#0d1117",
      "bg_secondary": "#161b22",
      "bg_tertiary": "#21262d",
      "bg_overlay": "#0d1117ee"
    },
    "cyberpunk": {
      "neon_cyan": "#00ffff",
      "neon_pink": "#ff006e",
      "neon_green": "#39ff14",
      "neon_purple": "#8a2be2",
      "electric_blue": "#0080ff"
    },
    "medieval": {
      "royal_gold": "#ffd700",
      "ancient_bronze": "#cd7f32",
      "battle_crimson": "#dc143c",
      "castle_stone": "#696969",
      "iron_gray": "#36454f"
    },
    "text": {
      "primary": "#e6edf3",
      "secondary": "#8b949e",
      "accent": "#58a6ff",
      "muted": "#6e7681"
    },
    "status": {
      "success": "#39ff14",
      "warning": "#ffd700",
      "error": "#dc143c",
      "info": "#00ffff"
    },
    "semantic": {
      "border_active": "cyberpunk.neon_cyan",
      "border_inactive": "medieval.castle_stone",
      "accent_primary": "cyberpunk.neon_cyan",
      "accent_secondary": "medieval.royal_gold",
      "shadow": "rgba(0, 0, 0, 0.8)"
    }
  },
  "typography": {
    "font_primary": "JetBrains Mono Nerd Font",
    "font_secondary": "Fira Code Nerd Font",
    "size_small": 11,
    "size_normal": 13,
    "size_large": 16,
    "size_title": 20
  },
  "spacing": {
    "gaps_inner": 8,
    "gaps_outer": 16,
    "border_width": 3,
    "rounding": 12,
    "margins": {
      "small": 4,
      "medium": 8,
      "large": 16,
      "xlarge": 24
    }
  },
  "effects": {
    "blur": {
      "enabled": true,
      "size": 8,
      "passes": 3,
      "vibrancy": 0.1696
    },
    "shadow": {
      "enabled": true,
      "range": 20,
      "render_power": 3
    },
    "animations": {
      "enabled": true,
      "speed_multiplier": 1.0,
      "curves": {
        "cyberpunk": "0.25, 0.46, 0.45, 0.94",
        "medieval": "0.68, -0.55, 0.265, 1.55",
        "smooth": "0.23, 1, 0.320, 1",
        "glow": "0.175, 0.885, 0.320, 1.275"
      }
    }
  },
  "workspaces": {
    "names": {
      "1": "The Keep",
      "2": "The Forge",
      "3": "The Library",
      "4": "The Tavern",
      "5": "The Market",
      "6": "The Stables",
      "7": "The Armory",
      "8": "The Tower",
      "9": "The Dungeon",
      "10": "The Throne Room"
    },
    "icons": {
      "1": "🏰",
      "2": "⚒️",
      "3": "📚",
      "4": "🍺",
      "5": "🏪",
      "6": "🐎",
      "7": "⚔️",
      "8": "🗼",
      "9": "🔒",
      "10": "👑"
    }
  },
  "components": {
    "waybar": {
      "height": 42,
      "margin_top": 8,
      "margin_sides": 16,
      "modules_left": ["custom/logo", "hyprland/workspaces", "hyprland/window"],
      "modules_center": ["clock"],
      "modules_right": ["custom/zerotier", "network", "bluetooth", "pulseaudio", "battery", "tray", "custom/config", "custom/power"]
    },
    "rofi": {
      "width": 600,
      "lines": 8,
      "location": "center"
    }
  }
}
EOF

    echo "📄 Generated default theme configuration"
    echo "cyberpunk-medieval" > "$SCRIPT_DIR/.current-theme"
}

# Function to handle time-based theme switching
handle_time_based_themes() {
    if [[ ! -f "$SCRIPT_DIR/.time-based-themes" ]]; then
        return 0
    fi

    local hour=$(date +%H)
    local current_theme=$(get_current_theme)
    local new_theme=""

    # Define time-based theme rules
    if [[ $hour -ge 6 && $hour -lt 12 ]]; then
        # Morning: Lighter theme
        new_theme="cyberpunk-medieval"
    elif [[ $hour -ge 12 && $hour -lt 18 ]]; then
        # Afternoon: Standard theme
        new_theme="cyberpunk-medieval"
    elif [[ $hour -ge 18 && $hour -lt 22 ]]; then
        # Evening: Warmer theme
        new_theme="cyberpunk-medieval"
    else
        # Night: Darker theme
        new_theme="dark-ages"
    fi

    if [[ "$new_theme" != "$current_theme" ]]; then
        echo "🕐 Time-based theme switch: $current_theme → $new_theme"
        echo "$new_theme" > "$SCRIPT_DIR/.current-theme"
        apply_startup_theme
    fi
}

# Function to check for theme updates
check_theme_updates() {
    if [[ ! -f "$SCRIPT_DIR/.check-theme-updates" ]]; then
        return 0
    fi

    # Check if theme config has been modified
    local config_mtime=$(stat -c %Y "$THEME_CONFIG" 2>/dev/null || echo "0")
    local last_check_file="$SCRIPT_DIR/.last-theme-check"
    local last_check=0

    if [[ -f "$last_check_file" ]]; then
        last_check=$(cat "$last_check_file")
    fi

    if [[ $config_mtime -gt $last_check ]]; then
        echo "🔄 Theme configuration updated, regenerating..."
        apply_startup_theme
        echo "$config_mtime" > "$last_check_file"
    fi
}

# Function to setup theme-related services
setup_theme_services() {
    # Start theme file watcher if inotify-tools is available
    if command -v inotifywait >/dev/null 2>&1; then
        (
            while inotifywait -e modify "$THEME_CONFIG" 2>/dev/null; do
                echo "📝 Theme config changed, regenerating..."
                sleep 1  # Debounce
                apply_startup_theme
            done
        ) &

        # Save PID for cleanup
        echo $! > "$SCRIPT_DIR/.theme-watcher-pid"
    fi

    # Setup time-based theme switching daemon
    if [[ -f "$SCRIPT_DIR/.time-based-themes" ]]; then
        (
            while true; do
                sleep 3600  # Check every hour
                handle_time_based_themes
            done
        ) &

        echo $! > "$SCRIPT_DIR/.time-theme-daemon-pid"
    fi
}

# Function to cleanup theme services
cleanup_theme_services() {
    # Kill theme watcher
    if [[ -f "$SCRIPT_DIR/.theme-watcher-pid" ]]; then
        local watcher_pid=$(cat "$SCRIPT_DIR/.theme-watcher-pid")
        kill "$watcher_pid" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/.theme-watcher-pid"
    fi

    # Kill time-based theme daemon
    if [[ -f "$SCRIPT_DIR/.time-theme-daemon-pid" ]]; then
        local daemon_pid=$(cat "$SCRIPT_DIR/.time-theme-daemon-pid")
        kill "$daemon_pid" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/.time-theme-daemon-pid"
    fi
}

# Function to handle theme errors
handle_theme_error() {
    local error_msg="$1"

    echo "❌ Theme error: $error_msg"

    # Try to restore from backup
    local backup_files=($(ls "$SCRIPT_DIR/backups"/theme-backup-*.json 2>/dev/null | sort -r))

    if [[ ${#backup_files[@]} -gt 0 ]]; then
        local latest_backup="${backup_files[0]}"
        echo "🔄 Attempting to restore from backup: $(basename "$latest_backup")"

        cp "$latest_backup" "$THEME_CONFIG"
        apply_startup_theme

        # Notify user
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "⚠️ Theme Restored" \
                "Theme error occurred, restored from backup\n$(basename "$latest_backup")" \
                -t 5000 -u normal
        fi
    else
        echo "🔧 No backup found, generating default theme..."
        generate_default_theme
        apply_startup_theme
    fi
}

# Function to validate theme integrity
validate_theme() {
    if [[ ! -f "$THEME_CONFIG" ]]; then
        return 1
    fi

    # Check if it's valid JSON
    if ! jq empty "$THEME_CONFIG" 2>/dev/null; then
        return 1
    fi

    # Check for required fields
    local required_fields=(".colors" ".typography" ".spacing")

    for field in "${required_fields[@]}"; do
        if ! jq -e "$field" "$THEME_CONFIG" >/dev/null 2>&1; then
            return 1
        fi
    done

    return 0
}

# Function to show startup theme info
show_startup_info() {
    local theme_name=$(get_current_theme)
    local theme_display_name="Unknown"

    if [[ -f "$THEME_CONFIG" ]]; then
        theme_display_name=$(jq -r '.meta.name // "Unknown"' "$THEME_CONFIG" 2>/dev/null)
    fi

    echo "🎨 Theme System Initialized"
    echo "   Current Theme: $theme_display_name ($theme_name)"
    echo "   Config: $THEME_CONFIG"
    echo "   Services: $(pgrep -f theme-watcher >/dev/null && echo "Watcher " || echo "")$(pgrep -f time-theme >/dev/null && echo "Time-based" || echo "")"
}

# Main startup function
main() {
    echo "🚀 Initializing theme system..."

    case "${1:-startup}" in
        "startup")
            # Full startup sequence
            if validate_theme; then
                apply_startup_theme
            else
                echo "⚠️ Theme validation failed"
                handle_theme_error "Invalid theme configuration"
            fi

            handle_time_based_themes
            check_theme_updates
            setup_theme_services
            show_startup_info
            ;;
        "apply")
            # Just apply the current theme
            apply_startup_theme
            ;;
        "validate")
            # Validate current theme
            if validate_theme; then
                echo "✅ Theme validation passed"
                exit 0
            else
                echo "❌ Theme validation failed"
                exit 1
            fi
            ;;
        "cleanup")
            # Cleanup theme services
            cleanup_theme_services
            echo "✅ Theme services cleaned up"
            ;;
        "time-check")
            # Force time-based theme check
            handle_time_based_themes
            ;;
        "restore")
            # Restore from backup
            handle_theme_error "Manual restore requested"
            ;;
        *)
            echo "🎨 Theme Startup Manager"
            echo ""
            echo "Usage: $0 {startup|apply|validate|cleanup|time-check|restore}"
            echo ""
            echo "Commands:"
            echo "  startup    - Full theme initialization (default)"
            echo "  apply      - Apply current theme"
            echo "  validate   - Validate theme configuration"
            echo "  cleanup    - Stop theme services"
            echo "  time-check - Check time-based theme switching"
            echo "  restore    - Restore theme from backup"
            ;;
    esac
}

# Handle script termination
trap cleanup_theme_services EXIT

# Run main function
main "$@"
