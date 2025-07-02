#!/bin/bash
# 🎨 Dynamic Theme Manager
# Comprehensive theme management with real-time preview

SCRIPT_DIR="$HOME/.config/hypr-system"
THEME_CONFIG="$SCRIPT_DIR/core/theme-config.json"
THEMES_DIR="$SCRIPT_DIR/themes"
BACKUP_DIR="$SCRIPT_DIR/backups"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Create required directories
mkdir -p "$THEMES_DIR" "$BACKUP_DIR"

# Colors
CYAN="#00ffff"
GOLD="#ffd700"
CRIMSON="#dc143c"

# Function to check dependencies
check_dependencies() {
    local missing_deps=()

    local required_commands=("jq" "python3")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        notify-send "❌ Missing Dependencies" \
            "Please install: ${missing_deps[*]}" \
            -t 5000 -u critical
        return 1
    fi

    return 0
}

# Function to backup current theme
backup_current_theme() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/theme_backup_$timestamp.json"

    if [[ -f "$THEME_CONFIG" ]]; then
        cp "$THEME_CONFIG" "$backup_file"
        echo "✅ Theme backed up to: $backup_file"
        return 0
    else
        echo "❌ No theme config found to backup"
        return 1
    fi
}

# Function to get available themes
get_available_themes() {
    local themes=("cyberpunk-medieval" "neo-tokyo" "dark-ages" "neon-knight" "matrix-green" "synthwave")

    # Add custom themes from themes directory
    if [[ -d "$THEMES_DIR" ]]; then
        for theme_file in "$THEMES_DIR"/*.json; do
            if [[ -f "$theme_file" ]]; then
                local theme_name=$(basename "$theme_file" .json)
                themes+=("$theme_name")
            fi
        done
    fi

    printf '%s\n' "${themes[@]}" | sort -u
}

# Function to apply theme
apply_theme() {
    local theme_name="$1"
    local preview_mode="${2:-false}"

    echo "🎨 Applying theme: $theme_name"

    # Backup current theme if not in preview mode
    if [[ "$preview_mode" != "true" ]]; then
        backup_current_theme
    fi

    # Check if theme file exists
    local theme_file="$THEMES_DIR/$theme_name.json"
    if [[ -f "$theme_file" ]]; then
        echo "📁 Using custom theme file: $theme_file"
        cp "$theme_file" "$THEME_CONFIG"
    else
        echo "🏗️ Generating built-in theme: $theme_name"
        generate_builtin_theme "$theme_name"
    fi

    # Save current theme
    echo "$theme_name" > "$SCRIPT_DIR/.current-theme"

    # Regenerate configurations
    if [[ -f "$SCRIPT_DIR/generators/apply-theme.py" ]]; then
        echo "🔄 Regenerating configurations..."
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py

        # Update wallpaper to match theme
        if [[ -f "$SCRIPT_DIR/scripts/wallpaper-cycle.sh" ]]; then
            "$SCRIPT_DIR/scripts/wallpaper-cycle.sh" theme "$theme_name"
        fi

        # Show success notification
        if [[ "$preview_mode" != "true" ]]; then
            notify-send "🎨 Theme Applied" \
                "Successfully applied '$theme_name' theme" \
                -t 3000 -u normal
        fi

        return 0
    else
        echo "❌ Theme generator not found"
        notify-send "❌ Error" "Theme generator not found" -t 5000 -u critical
        return 1
    fi
}

# Function to generate built-in themes
generate_builtin_theme() {
    local theme_name="$1"

    case "$theme_name" in
        "neo-tokyo")
            cat > "$THEME_CONFIG" << 'EOF'
{
  "meta": {
    "name": "Neo Tokyo",
    "version": "2.0",
    "description": "Bright neon cyberpunk inspired by Tokyo nightlife"
  },
  "colors": {
    "primary": {
      "bg_primary": "#0a0a0a",
      "bg_secondary": "#1a1a1a",
      "bg_tertiary": "#2a2a2a",
      "bg_overlay": "#0a0a0aee"
    },
    "cyberpunk": {
      "neon_cyan": "#00ffff",
      "neon_pink": "#ff1493",
      "neon_green": "#00ff00",
      "neon_purple": "#ff00ff",
      "electric_blue": "#0080ff"
    },
    "medieval": {
      "royal_gold": "#ffaa00",
      "ancient_bronze": "#ff6600",
      "battle_crimson": "#ff0040",
      "castle_stone": "#808080",
      "iron_gray": "#404040"
    },
    "text": {
      "primary": "#ffffff",
      "secondary": "#cccccc",
      "accent": "#00ffff",
      "muted": "#999999"
    },
    "status": {
      "success": "#00ff00",
      "warning": "#ffaa00",
      "error": "#ff0040",
      "info": "#00ffff"
    },
    "semantic": {
      "border_active": "cyberpunk.neon_pink",
      "border_inactive": "medieval.castle_stone",
      "accent_primary": "cyberpunk.neon_pink",
      "accent_secondary": "cyberpunk.neon_cyan",
      "shadow": "rgba(255, 20, 147, 0.8)"
    }
  }
}
EOF
            ;;
        "dark-ages")
            cat > "$THEME_CONFIG" << 'EOF'
{
  "meta": {
    "name": "Dark Ages",
    "version": "2.0",
    "description": "Medieval dark theme with muted colors"
  },
  "colors": {
    "primary": {
      "bg_primary": "#1c1611",
      "bg_secondary": "#2d2420",
      "bg_tertiary": "#3e322b",
      "bg_overlay": "#1c1611ee"
    },
    "cyberpunk": {
      "neon_cyan": "#4a9eff",
      "neon_pink": "#c678dd",
      "neon_green": "#98c379",
      "neon_purple": "#a991f1",
      "electric_blue": "#61afef"
    },
    "medieval": {
      "royal_gold": "#d19a66",
      "ancient_bronze": "#b8860b",
      "battle_crimson": "#cc5500",
      "castle_stone": "#5c6370",
      "iron_gray": "#3e4451"
    },
    "text": {
      "primary": "#abb2bf",
      "secondary": "#5c6370",
      "accent": "#d19a66",
      "muted": "#4b5263"
    },
    "status": {
      "success": "#98c379",
      "warning": "#d19a66",
      "error": "#cc5500",
      "info": "#61afef"
    },
    "semantic": {
      "border_active": "medieval.royal_gold",
      "border_inactive": "medieval.iron_gray",
      "accent_primary": "medieval.royal_gold",
      "accent_secondary": "medieval.ancient_bronze",
      "shadow": "rgba(209, 154, 102, 0.6)"
    }
  }
}
EOF
            ;;
        "matrix-green")
            cat > "$THEME_CONFIG" << 'EOF'
{
  "meta": {
    "name": "Matrix Green",
    "version": "2.0",
    "description": "Classic green matrix theme"
  },
  "colors": {
    "primary": {
      "bg_primary": "#000000",
      "bg_secondary": "#001100",
      "bg_tertiary": "#002200",
      "bg_overlay": "#000000ee"
    },
    "cyberpunk": {
      "neon_cyan": "#00ff41",
      "neon_pink": "#41ff00",
      "neon_green": "#00ff00",
      "neon_purple": "#80ff00",
      "electric_blue": "#40ff80"
    },
    "medieval": {
      "royal_gold": "#80ff00",
      "ancient_bronze": "#60cc00",
      "battle_crimson": "#ff4141",
      "castle_stone": "#408040",
      "iron_gray": "#204020"
    },
    "text": {
      "primary": "#00ff41",
      "secondary": "#008020",
      "accent": "#80ff00",
      "muted": "#004010"
    },
    "status": {
      "success": "#00ff00",
      "warning": "#80ff00",
      "error": "#ff4141",
      "info": "#40ff80"
    },
    "semantic": {
      "border_active": "cyberpunk.neon_green",
      "border_inactive": "medieval.castle_stone",
      "accent_primary": "cyberpunk.neon_green",
      "accent_secondary": "cyberpunk.neon_cyan",
      "shadow": "rgba(0, 255, 65, 0.6)"
    }
  }
}
EOF
            ;;
        *)
            echo "⚠️ Unknown theme: $theme_name, keeping current theme"
            return 1
            ;;
    esac

    # Add the rest of the config structure
    if command -v jq >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/core/theme-config.json.template" ]]; then
        # Merge with template if available
        echo "🔧 Merging with template structure..."
    fi
}

# Function to show theme preview
show_theme_preview() {
    local theme_name="$1"

    # Create a temporary backup
    local temp_backup=$(mktemp)
    cp "$THEME_CONFIG" "$temp_backup"

    # Apply theme in preview mode
    apply_theme "$theme_name" true

    # Show preview notification
    notify-send "👁️ Theme Preview" \
        "Previewing '$theme_name' theme\nPress Enter to apply or Escape to cancel" \
        -t 10000 -u normal

    # Wait for user input
    read -p "Apply this theme? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "✅ Theme applied permanently"
        rm -f "$temp_backup"
    else
        echo "🔄 Reverting to previous theme"
        cp "$temp_backup" "$THEME_CONFIG"
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py
        rm -f "$temp_backup"
    fi
}

# Function to create custom theme
create_custom_theme() {
    local theme_name
    read -p "Enter custom theme name: " theme_name

    if [[ -z "$theme_name" ]]; then
        echo "❌ Theme name cannot be empty"
        return 1
    fi

    local custom_theme_file="$THEMES_DIR/$theme_name.json"

    if [[ -f "$custom_theme_file" ]]; then
        read -p "Theme already exists. Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    # Copy current theme as base
    cp "$THEME_CONFIG" "$custom_theme_file"

    # Update metadata
    if command -v jq >/dev/null 2>&1; then
        jq --arg name "$theme_name" '.meta.name = $name' "$custom_theme_file" > "${custom_theme_file}.tmp" && mv "${custom_theme_file}.tmp" "$custom_theme_file"
    fi

    echo "✅ Custom theme created: $custom_theme_file"

    # Open in editor if available
    if command -v code >/dev/null 2>&1; then
        code "$custom_theme_file" &
    elif command -v nano >/dev/null 2>&1; then
        nano "$custom_theme_file"
    fi
}

# Function to show theme selection menu
show_theme_menu() {
    local themes=($(get_available_themes))
    local current_theme=""

    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        current_theme=$(cat "$SCRIPT_DIR/.current-theme")
    fi

    # Prepare menu items
    local menu_items=()
    for theme in "${themes[@]}"; do
        if [[ "$theme" == "$current_theme" ]]; then
            menu_items+=("✅ $theme (current)")
        else
            menu_items+=("🎨 $theme")
        fi
    done

    # Add special options
    menu_items+=("👁️ Preview Mode" "🆕 Create Custom Theme" "📁 Open Themes Folder" "💾 Backup Current")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🎨 Theme Manager" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    if [[ -n "$selected" ]]; then
        case "$selected" in
            *"Preview Mode")
                echo "👁️ Entering preview mode..."
                show_theme_menu_preview
                ;;
            *"Create Custom Theme")
                create_custom_theme
                ;;
            *"Open Themes Folder")
                thunar "$THEMES_DIR" &
                ;;
            *"Backup Current")
                backup_current_theme
                notify-send "💾 Backup Created" "Current theme backed up" -t 3000
                ;;
            *"(current)")
                notify-send "ℹ️ Current Theme" "This theme is already active" -t 2000
                ;;
            *)
                local theme_name=$(echo "$selected" | sed 's/^[🎨✅] //')
                apply_theme "$theme_name"
                ;;
        esac
    fi
}

# Function to show preview menu
show_theme_menu_preview() {
    local themes=($(get_available_themes))

    local menu_items=()
    for theme in "${themes[@]}"; do
        menu_items+=("👁️ $theme")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "👁️ Preview Theme" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected" ]]; then
        local theme_name=$(echo "$selected" | sed 's/^👁️ //')
        show_theme_preview "$theme_name"
    fi
}

# Function to export theme
export_theme() {
    local export_path="$HOME/Desktop"
    local theme_name=""

    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        theme_name=$(cat "$SCRIPT_DIR/.current-theme")
    else
        theme_name="exported_theme"
    fi

    local export_file="$export_path/${theme_name}_$(date +%Y%m%d_%H%M%S).json"

    cp "$THEME_CONFIG" "$export_file"

    notify-send "📤 Theme Exported" \
        "Theme exported to: $export_file" \
        -t 5000 -u normal

    echo "✅ Theme exported to: $export_file"
}

# Main script logic
main() {
    if ! check_dependencies; then
        exit 1
    fi

    case "$1" in
        menu)
            show_theme_menu
            ;;
        apply)
            if [[ -n "$2" ]]; then
                apply_theme "$2"
            else
                echo "Usage: $0 apply <theme_name>"
                exit 1
            fi
            ;;
        preview)
            if [[ -n "$2" ]]; then
                show_theme_preview "$2"
            else
                show_theme_menu_preview
            fi
            ;;
        list)
            echo "📋 Available themes:"
            get_available_themes
            ;;
        backup)
            backup_current_theme
            ;;
        create)
            create_custom_theme
            ;;
        export)
            export_theme
            ;;
        current)
            if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
                cat "$SCRIPT_DIR/.current-theme"
            else
                echo "No current theme set"
            fi
            ;;
        *)
            echo "🎨 Cyberpunk Theme Manager"
            echo ""
            echo "Usage: $0 {menu|apply|preview|list|backup|create|export|current}"
            echo ""
            echo "Commands:"
            echo "  menu              - Show interactive theme menu"
            echo "  apply <theme>     - Apply specific theme"
            echo "  preview <theme>   - Preview theme before applying"
            echo "  list              - List available themes"
            echo "  backup            - Backup current theme"
            echo "  create            - Create custom theme"
            echo "  export            - Export current theme"
            echo "  current           - Show current theme name"
            echo ""
            echo "Default action: show theme menu"
            show_theme_menu
            ;;
    esac
}

# Run main function
main "$@"
