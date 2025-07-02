#!/bin/bash
# 🖼️ Dynamic Wallpaper Manager with Theme Integration

SCRIPT_DIR="$HOME/.config/hypr-system"
WALLPAPER_BASE_DIR="$SCRIPT_DIR/wallpapers"
CURRENT_WALLPAPER_FILE="$SCRIPT_DIR/.current-wallpaper"
THEME_CONFIG="$SCRIPT_DIR/core/theme-config.json"

# Create wallpaper directories if they don't exist
mkdir -p "$WALLPAPER_BASE_DIR"/{cyberpunk-medieval,transitions,dynamic}

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"

# Transition effects for swww
TRANSITIONS=("wave" "wipe" "center" "outer" "random" "grow" "fade")

# Function to initialize swww
init_swww() {
    if ! pgrep -x "swww-daemon" > /dev/null; then
        echo "🔄 Starting swww daemon..."
        swww init
        sleep 2
    fi
}

# Function to get current theme
get_current_theme() {
    local theme="cyberpunk-medieval"  # default

    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        theme=$(cat "$SCRIPT_DIR/.current-theme")
    fi

    echo "$theme"
}

# Function to get wallpapers for current theme
get_theme_wallpapers() {
    local theme="$1"
    local theme_dir="$WALLPAPER_BASE_DIR/$theme"

    # Create theme directory if it doesn't exist
    mkdir -p "$theme_dir"

    # Find all image files
    find "$theme_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | sort
}

# Function to download default wallpapers if none exist
setup_default_wallpapers() {
    local theme_dir="$WALLPAPER_BASE_DIR/cyberpunk-medieval"

    if [[ ! -d "$theme_dir" ]] || [[ -z "$(ls -A "$theme_dir" 2>/dev/null)" ]]; then
        echo "📥 Setting up default wallpapers..."
        mkdir -p "$theme_dir"

        # Create placeholder wallpapers with gradients (fallback)
        if command -v convert >/dev/null 2>&1; then
            echo "🎨 Creating gradient wallpapers..."

            # Cyberpunk gradient
            convert -size 1920x1080 gradient:"#0d1117-#00ffff" "$theme_dir/cyberpunk-gradient.png"

            # Medieval gradient
            convert -size 1920x1080 gradient:"#0d1117-#ffd700" "$theme_dir/medieval-gradient.png"

            # Purple-cyan gradient
            convert -size 1920x1080 gradient:"#8a2be2-#00ffff" "$theme_dir/cyber-purple.png"

            echo "✅ Created gradient wallpapers"
        else
            # Create a simple solid color wallpaper
            echo "Creating solid color wallpaper..."
            printf "Creating fallback wallpaper...\n"
        fi
    fi
}

# Function to set wallpaper with transition
set_wallpaper() {
    local wallpaper_path="$1"
    local transition="${2:-random}"
    local duration="${3:-2}"

    if [[ ! -f "$wallpaper_path" ]]; then
        echo "❌ Wallpaper not found: $wallpaper_path"
        return 1
    fi

    init_swww

    echo "🖼️ Setting wallpaper: $(basename "$wallpaper_path")"

    # Set random transition if specified
    if [[ "$transition" == "random" ]]; then
        transition="${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}"
    fi

    # Apply wallpaper with transition
    swww img "$wallpaper_path" \
        --transition-type "$transition" \
        --transition-duration "$duration" \
        --transition-fps 60

    # Save current wallpaper
    echo "$wallpaper_path" > "$CURRENT_WALLPAPER_FILE"

    # Show notification
    notify-send "🖼️ Wallpaper Changed" \
        "$(basename "$wallpaper_path")\nTransition: $transition" \
        -t 3000 \
        -u normal
}

# Function to cycle to next wallpaper
cycle_wallpaper() {
    local theme="$(get_current_theme)"
    local wallpapers=($(get_theme_wallpapers "$theme"))

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        echo "⚠️ No wallpapers found for theme: $theme"
        setup_default_wallpapers
        wallpapers=($(get_theme_wallpapers "$theme"))

        if [[ ${#wallpapers[@]} -eq 0 ]]; then
            notify-send "❌ No Wallpapers" "Add wallpapers to $WALLPAPER_BASE_DIR/$theme" -t 5000
            return 1
        fi
    fi

    local current_wallpaper=""
    local next_wallpaper=""

    # Get current wallpaper
    if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
        current_wallpaper=$(cat "$CURRENT_WALLPAPER_FILE")
    fi

    # Find next wallpaper
    if [[ -n "$current_wallpaper" ]]; then
        for i in "${!wallpapers[@]}"; do
            if [[ "${wallpapers[$i]}" == "$current_wallpaper" ]]; then
                local next_index=$(( (i + 1) % ${#wallpapers[@]} ))
                next_wallpaper="${wallpapers[$next_index]}"
                break
            fi
        done
    fi

    # Default to first wallpaper if not found
    if [[ -z "$next_wallpaper" ]]; then
        next_wallpaper="${wallpapers[0]}"
    fi

    set_wallpaper "$next_wallpaper" "random"
}

# Function to set random wallpaper
random_wallpaper() {
    local theme="$(get_current_theme)"
    local wallpapers=($(get_theme_wallpapers "$theme"))

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        echo "⚠️ No wallpapers found for theme: $theme"
        return 1
    fi

    local random_index=$((RANDOM % ${#wallpapers[@]}))
    local random_wallpaper="${wallpapers[$random_index]}"

    set_wallpaper "$random_wallpaper" "random"
}

# Function to handle time-based wallpapers
time_based_wallpaper() {
    local hour=$(date +%H)
    local theme="$(get_current_theme)"
    local wallpapers=($(get_theme_wallpapers "$theme"))

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        return 1
    fi

    # Determine wallpaper based on time of day
    local wallpaper_index
    if [[ $hour -ge 6 && $hour -lt 12 ]]; then
        # Morning: First quarter of wallpapers
        wallpaper_index=$((RANDOM % (${#wallpapers[@]} / 4 + 1)))
    elif [[ $hour -ge 12 && $hour -lt 17 ]]; then
        # Afternoon: Second quarter
        wallpaper_index=$(((${#wallpapers[@]} / 4) + (RANDOM % (${#wallpapers[@]} / 4 + 1))))
    elif [[ $hour -ge 17 && $hour -lt 21 ]]; then
        # Evening: Third quarter
        wallpaper_index=$(((${#wallpapers[@]} / 2) + (RANDOM % (${#wallpapers[@]} / 4 + 1))))
    else
        # Night: Last quarter (darker wallpapers)
        wallpaper_index=$(((${#wallpapers[@]} * 3 / 4) + (RANDOM % (${#wallpapers[@]} / 4))))
    fi

    # Ensure index is within bounds
    wallpaper_index=$((wallpaper_index % ${#wallpapers[@]}))

    set_wallpaper "${wallpapers[$wallpaper_index]}" "fade" 3
}

# Function to show wallpaper menu
show_wallpaper_menu() {
    local theme="$(get_current_theme)"
    local wallpapers=($(get_theme_wallpapers "$theme"))

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        notify-send "❌ No Wallpapers" "Add wallpapers to $WALLPAPER_BASE_DIR/$theme" -t 5000
        return 1
    fi

    # Create menu items
    local menu_items=()
    for wallpaper in "${wallpapers[@]}"; do
        local basename=$(basename "$wallpaper")
        menu_items+=("🖼️ $basename")
    done

    # Add special options
    menu_items+=("🎲 Random Wallpaper" "🔄 Cycle Next" "⏰ Time-based" "📁 Open Wallpaper Folder")

    # Show rofi menu
    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🖼️ Wallpapers" \
        -theme "$HOME/.config/rofi/themes/cyberpunk-medieval.rasi")

    if [[ -n "$selected" ]]; then
        case "$selected" in
            "🎲 Random Wallpaper")
                random_wallpaper
                ;;
            "🔄 Cycle Next")
                cycle_wallpaper
                ;;
            "⏰ Time-based")
                time_based_wallpaper
                ;;
            "📁 Open Wallpaper Folder")
                thunar "$WALLPAPER_BASE_DIR/$theme" &
                ;;
            *)
                # Extract filename and find full path
                local filename=$(echo "$selected" | sed 's/🖼️ //')
                for wallpaper in "${wallpapers[@]}"; do
                    if [[ "$(basename "$wallpaper")" == "$filename" ]]; then
                        set_wallpaper "$wallpaper"
                        break
                    fi
                done
                ;;
        esac
    fi
}

# Function to watch for theme changes
watch_theme_changes() {
    local current_theme="$(get_current_theme)"

    # Set appropriate wallpaper for new theme
    local wallpapers=($(get_theme_wallpapers "$current_theme"))
    if [[ ${#wallpapers[@]} -gt 0 ]]; then
        set_wallpaper "${wallpapers[0]}" "wave" 3
    fi
}

# Main command handling
case "$1" in
    init)
        echo "🚀 Initializing wallpaper system..."
        setup_default_wallpapers
        init_swww

        # Set initial wallpaper
        local theme="$(get_current_theme)"
        local wallpapers=($(get_theme_wallpapers "$theme"))

        if [[ ${#wallpapers[@]} -gt 0 ]]; then
            if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
                local saved_wallpaper=$(cat "$CURRENT_WALLPAPER_FILE")
                if [[ -f "$saved_wallpaper" ]]; then
                    set_wallpaper "$saved_wallpaper" "fade"
                else
                    set_wallpaper "${wallpapers[0]}" "fade"
                fi
            else
                set_wallpaper "${wallpapers[0]}" "fade"
            fi
        fi
        ;;
    next|cycle)
        cycle_wallpaper
        ;;
    random)
        random_wallpaper
        ;;
    time)
        time_based_wallpaper
        ;;
    menu)
        show_wallpaper_menu
        ;;
    theme)
        if [[ -n "$2" ]]; then
            echo "$2" > "$SCRIPT_DIR/.current-theme"
            watch_theme_changes
        else
            echo "Usage: $0 theme <theme_name>"
        fi
        ;;
    set)
        if [[ -n "$2" && -f "$2" ]]; then
            set_wallpaper "$2" "${3:-random}"
        else
            echo "Usage: $0 set <wallpaper_path> [transition]"
        fi
        ;;
    list)
        local theme="$(get_current_theme)"
        echo "Wallpapers for theme '$theme':"
        get_theme_wallpapers "$theme"
        ;;
    *)
        echo "🖼️ Cyberpunk Wallpaper Manager"
        echo ""
        echo "Usage: $0 {init|next|random|time|menu|theme|set|list}"
        echo ""
        echo "Commands:"
        echo "  init               - Initialize wallpaper system"
        echo "  next/cycle         - Cycle to next wallpaper"
        echo "  random             - Set random wallpaper"
        echo "  time               - Set time-based wallpaper"
        echo "  menu               - Show wallpaper selection menu"
        echo "  theme <name>       - Switch to theme and set wallpaper"
        echo "  set <path> [trans] - Set specific wallpaper with transition"
        echo "  list               - List available wallpapers"
        echo ""
        echo "Default action: cycle to next wallpaper"
        cycle_wallpaper
        ;;
esac
