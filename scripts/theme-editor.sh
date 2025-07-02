#!/bin/bash
# 🎨 Visual Theme Editor
# Interactive interface for editing theme colors, fonts, and visual settings

SCRIPT_DIR="$HOME/.config/hypr-system"
THEME_CONFIG="$SCRIPT_DIR/core/theme-config.json"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"

# Function to check dependencies
check_dependencies() {
    if ! command -v jq >/dev/null 2>&1; then
        notify-send "❌ Missing Dependency" "jq is required for theme editing" -t 5000 -u critical
        return 1
    fi

    if [[ ! -f "$THEME_CONFIG" ]]; then
        notify-send "❌ Theme Config Missing" "Theme configuration file not found" -t 5000 -u critical
        return 1
    fi

    return 0
}

# Function to get current value from theme config
get_theme_value() {
    local key="$1"
    jq -r "$key // empty" "$THEME_CONFIG" 2>/dev/null
}

# Function to set theme value
set_theme_value() {
    local key="$1"
    local value="$2"
    local temp_file=$(mktemp)

    if jq "$key = \"$value\"" "$THEME_CONFIG" > "$temp_file"; then
        mv "$temp_file" "$THEME_CONFIG"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Function to show color palette editor
edit_color_palette() {
    local category="$1"
    local colors=($(jq -r ".colors.$category | keys[]" "$THEME_CONFIG" 2>/dev/null))

    if [[ ${#colors[@]} -eq 0 ]]; then
        notify-send "❌ No Colors Found" "No colors found in category $category" -t 3000
        return 1
    fi

    # Create menu items with current colors
    local menu_items=()
    for color in "${colors[@]}"; do
        local current_value=$(get_theme_value ".colors.$category.$color")
        menu_items+=("🎨 $color: $current_value")
    done

    menu_items+=("➕ Add New Color" "🔙 Back to Categories")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🎨 Edit $category Colors" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "➕ Add New Color")
            add_new_color "$category"
            ;;
        "🔙 Back to Categories")
            return 0
            ;;
        *)
            if [[ "$selected" =~ ^🎨\ ([^:]+): ]]; then
                local color_name="${BASH_REMATCH[1]}"
                edit_single_color "$category" "$color_name"
            fi
            ;;
    esac
}

# Function to edit a single color
edit_single_color() {
    local category="$1"
    local color_name="$2"
    local current_value=$(get_theme_value ".colors.$category.$color_name")

    local options=(
        "🎨 Change Color Value"
        "👁️ Preview Color"
        "🗑️ Delete Color"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${options[@]}" | \
        rofi -dmenu -p "🎨 $color_name ($current_value)" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🎨 Change Color Value")
            local new_value=$(echo "$current_value" | rofi -dmenu -p "Enter new color value:")
            if [[ -n "$new_value" ]]; then
                if [[ "$new_value" =~ ^#[0-9a-fA-F]{6}$ ]] || [[ "$new_value" =~ ^rgba?\( ]]; then
                    set_theme_value ".colors.$category.$color_name" "$new_value"
                    notify-send "🎨 Color Updated" "$color_name set to $new_value" -t 3000

                    # Ask if user wants to apply changes
                    if rofi -dmenu -p "Apply changes now?" <<< $'Yes\nNo' | grep -q "Yes"; then
                        apply_theme_changes
                    fi
                else
                    notify-send "❌ Invalid Color" "Please use hex (#ffffff) or rgba() format" -t 3000
                fi
            fi
            ;;
        "👁️ Preview Color")
            show_color_preview "$current_value"
            ;;
        "🗑️ Delete Color")
            if rofi -dmenu -p "Delete $color_name?" <<< $'Yes\nNo' | grep -q "Yes"; then
                local temp_file=$(mktemp)
                jq "del(.colors.$category.$color_name)" "$THEME_CONFIG" > "$temp_file" && mv "$temp_file" "$THEME_CONFIG"
                notify-send "🗑️ Color Deleted" "$color_name removed from $category" -t 3000
            fi
            ;;
    esac
}

# Function to add new color
add_new_color() {
    local category="$1"

    local color_name=$(echo "" | rofi -dmenu -p "Enter color name:")
    if [[ -z "$color_name" ]]; then
        return 1
    fi

    local color_value=$(echo "#" | rofi -dmenu -p "Enter color value (hex or rgba):")
    if [[ -z "$color_value" ]]; then
        return 1
    fi

    if [[ "$color_value" =~ ^#[0-9a-fA-F]{6}$ ]] || [[ "$color_value" =~ ^rgba?\( ]]; then
        set_theme_value ".colors.$category.$color_name" "$color_value"
        notify-send "✅ Color Added" "$color_name added to $category" -t 3000
    else
        notify-send "❌ Invalid Color" "Please use hex (#ffffff) or rgba() format" -t 3000
    fi
}

# Function to show color preview
show_color_preview() {
    local color="$1"

    # Create a temporary notification with the color
    notify-send "🎨 Color Preview" \
        "Color: $color\n\nThis is how the color looks in notifications" \
        -t 5000 -u normal

    # If we have a color picker available, show it
    if command -v gpick >/dev/null 2>&1; then
        gpick &
    elif command -v gcolor3 >/dev/null 2>&1; then
        gcolor3 &
    fi
}

# Function to edit typography settings
edit_typography() {
    local fonts=(
        "font_primary"
        "font_secondary"
        "size_small"
        "size_normal"
        "size_large"
        "size_title"
    )

    local menu_items=()
    for font_setting in "${fonts[@]}"; do
        local current_value=$(get_theme_value ".typography.$font_setting")
        menu_items+=("📝 $font_setting: $current_value")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "📝 Typography Settings" \
        -theme "$ROFI_THEME")

    if [[ "$selected" =~ ^📝\ ([^:]+): ]]; then
        local setting_name="${BASH_REMATCH[1]}"
        local current_value=$(get_theme_value ".typography.$setting_name")

        local new_value=$(echo "$current_value" | rofi -dmenu -p "Enter new value for $setting_name:")
        if [[ -n "$new_value" ]]; then
            set_theme_value ".typography.$setting_name" "$new_value"
            notify-send "📝 Typography Updated" "$setting_name set to $new_value" -t 3000

            if rofi -dmenu -p "Apply changes now?" <<< $'Yes\nNo' | grep -q "Yes"; then
                apply_theme_changes
            fi
        fi
    fi
}

# Function to edit spacing settings
edit_spacing() {
    local spacing_settings=(
        "gaps_inner"
        "gaps_outer"
        "border_width"
        "rounding"
    )

    local menu_items=()
    for setting in "${spacing_settings[@]}"; do
        local current_value=$(get_theme_value ".spacing.$setting")
        menu_items+=("📏 $setting: $current_value")
    done

    # Add margin settings
    local margins=($(jq -r '.spacing.margins | keys[]' "$THEME_CONFIG" 2>/dev/null))
    for margin in "${margins[@]}"; do
        local current_value=$(get_theme_value ".spacing.margins.$margin")
        menu_items+=("📐 margin_$margin: $current_value")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "📏 Spacing Settings" \
        -theme "$ROFI_THEME")

    if [[ "$selected" =~ ^📏\ ([^:]+): ]] || [[ "$selected" =~ ^📐\ margin_([^:]+): ]]; then
        local setting_name="${BASH_REMATCH[1]}"
        local current_value
        local key_path

        if [[ "$selected" =~ ^📐 ]]; then
            # Margin setting
            setting_name="${BASH_REMATCH[1]}"
            current_value=$(get_theme_value ".spacing.margins.$setting_name")
            key_path=".spacing.margins.$setting_name"
        else
            # Regular spacing setting
            current_value=$(get_theme_value ".spacing.$setting_name")
            key_path=".spacing.$setting_name"
        fi

        local new_value=$(echo "$current_value" | rofi -dmenu -p "Enter new value for $setting_name:")
        if [[ -n "$new_value" ]] && [[ "$new_value" =~ ^[0-9]+$ ]]; then
            set_theme_value "$key_path" "$new_value"
            notify-send "📏 Spacing Updated" "$setting_name set to $new_value" -t 3000

            if rofi -dmenu -p "Apply changes now?" <<< $'Yes\nNo' | grep -q "Yes"; then
                apply_theme_changes
            fi
        else
            notify-send "❌ Invalid Value" "Please enter a numeric value" -t 3000
        fi
    fi
}

# Function to edit effects settings
edit_effects() {
    local effects_menu=(
        "🔲 Blur Settings"
        "🌑 Shadow Settings"
        "✨ Animation Settings"
    )

    local selected=$(printf '%s\n' "${effects_menu[@]}" | \
        rofi -dmenu -p "✨ Effects Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🔲 Blur Settings")
            edit_blur_settings
            ;;
        "🌑 Shadow Settings")
            edit_shadow_settings
            ;;
        "✨ Animation Settings")
            edit_animation_settings
            ;;
    esac
}

# Function to edit blur settings
edit_blur_settings() {
    local blur_settings=(
        "enabled"
        "size"
        "passes"
        "vibrancy"
    )

    local menu_items=()
    for setting in "${blur_settings[@]}"; do
        local current_value=$(get_theme_value ".effects.blur.$setting")
        menu_items+=("🔲 $setting: $current_value")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🔲 Blur Settings" \
        -theme "$ROFI_THEME")

    if [[ "$selected" =~ ^🔲\ ([^:]+): ]]; then
        local setting_name="${BASH_REMATCH[1]}"
        local current_value=$(get_theme_value ".effects.blur.$setting_name")

        local new_value
        if [[ "$setting_name" == "enabled" ]]; then
            new_value=$(rofi -dmenu -p "Enable blur?" <<< $'true\nfalse')
        else
            new_value=$(echo "$current_value" | rofi -dmenu -p "Enter new value for $setting_name:")
        fi

        if [[ -n "$new_value" ]]; then
            set_theme_value ".effects.blur.$setting_name" "$new_value"
            notify-send "🔲 Blur Updated" "$setting_name set to $new_value" -t 3000
        fi
    fi
}

# Function to edit shadow settings
edit_shadow_settings() {
    local shadow_settings=(
        "enabled"
        "range"
        "render_power"
    )

    local menu_items=()
    for setting in "${shadow_settings[@]}"; do
        local current_value=$(get_theme_value ".effects.shadow.$setting")
        menu_items+=("🌑 $setting: $current_value")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🌑 Shadow Settings" \
        -theme "$ROFI_THEME")

    if [[ "$selected" =~ ^🌑\ ([^:]+): ]]; then
        local setting_name="${BASH_REMATCH[1]}"
        local current_value=$(get_theme_value ".effects.shadow.$setting_name")

        local new_value
        if [[ "$setting_name" == "enabled" ]]; then
            new_value=$(rofi -dmenu -p "Enable shadows?" <<< $'true\nfalse')
        else
            new_value=$(echo "$current_value" | rofi -dmenu -p "Enter new value for $setting_name:")
        fi

        if [[ -n "$new_value" ]]; then
            set_theme_value ".effects.shadow.$setting_name" "$new_value"
            notify-send "🌑 Shadow Updated" "$setting_name set to $new_value" -t 3000
        fi
    fi
}

# Function to edit animation settings
edit_animation_settings() {
    local anim_settings=(
        "enabled"
        "speed_multiplier"
    )

    local menu_items=()
    for setting in "${anim_settings[@]}"; do
        local current_value=$(get_theme_value ".effects.animations.$setting")
        menu_items+=("✨ $setting: $current_value")
    done

    # Add curve settings
    local curves=($(jq -r '.effects.animations.curves | keys[]' "$THEME_CONFIG" 2>/dev/null))
    for curve in "${curves[@]}"; do
        local current_value=$(get_theme_value ".effects.animations.curves.$curve")
        menu_items+=("📈 curve_$curve: $current_value")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "✨ Animation Settings" \
        -theme "$ROFI_THEME")

    if [[ "$selected" =~ ^✨\ ([^:]+): ]]; then
        local setting_name="${BASH_REMATCH[1]}"
        local current_value=$(get_theme_value ".effects.animations.$setting_name")

        local new_value
        if [[ "$setting_name" == "enabled" ]]; then
            new_value=$(rofi -dmenu -p "Enable animations?" <<< $'true\nfalse')
        else
            new_value=$(echo "$current_value" | rofi -dmenu -p "Enter new value for $setting_name:")
        fi

        if [[ -n "$new_value" ]]; then
            set_theme_value ".effects.animations.$setting_name" "$new_value"
            notify-send "✨ Animation Updated" "$setting_name set to $new_value" -t 3000
        fi
    elif [[ "$selected" =~ ^📈\ curve_([^:]+): ]]; then
        local curve_name="${BASH_REMATCH[1]}"
        local current_value=$(get_theme_value ".effects.animations.curves.$curve_name")

        local new_value=$(echo "$current_value" | rofi -dmenu -p "Enter bezier curve for $curve_name:")
        if [[ -n "$new_value" ]]; then
            set_theme_value ".effects.animations.curves.$curve_name" "$new_value"
            notify-send "📈 Curve Updated" "$curve_name set to $new_value" -t 3000
        fi
    fi
}

# Function to apply theme changes
apply_theme_changes() {
    notify-send "🔄 Applying Changes" "Regenerating configuration..." -t 3000

    if [[ -f "$SCRIPT_DIR/generators/apply-theme.py" ]]; then
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py
        notify-send "✅ Changes Applied" "Theme updated successfully" -t 3000
    else
        notify-send "❌ Error" "Theme generator not found" -t 5000 -u critical
    fi
}

# Main theme editor menu
show_theme_editor() {
    local main_menu=(
        "🎨 Color Palette"
        "📝 Typography"
        "📏 Spacing & Layout"
        "✨ Effects & Animations"
        "🔄 Apply All Changes"
        "👁️ Preview Current Theme"
        "💾 Save & Exit"
    )

    local selected=$(printf '%s\n' "${main_menu[@]}" | \
        rofi -dmenu -p "🎨 Theme Editor" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "🎨 Color Palette")
            show_color_categories
            ;;
        "📝 Typography")
            edit_typography
            ;;
        "📏 Spacing & Layout")
            edit_spacing
            ;;
        "✨ Effects & Animations")
            edit_effects
            ;;
        "🔄 Apply All Changes")
            apply_theme_changes
            ;;
        "👁️ Preview Current Theme")
            preview_theme
            ;;
        "💾 Save & Exit")
            apply_theme_changes
            return 0
            ;;
        *)
            return 0
            ;;
    esac

    # Return to main menu unless exiting
    show_theme_editor
}

# Function to show color categories
show_color_categories() {
    local categories=($(jq -r '.colors | keys[]' "$THEME_CONFIG" 2>/dev/null))

    local menu_items=()
    for category in "${categories[@]}"; do
        local color_count=$(jq -r ".colors.$category | length" "$THEME_CONFIG" 2>/dev/null)
        menu_items+=("🎨 $category ($color_count colors)")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🎨 Color Categories" \
        -theme "$ROFI_THEME")

    if [[ "$selected" =~ ^🎨\ ([^\ ]+) ]]; then
        local category="${BASH_REMATCH[1]}"
        edit_color_palette "$category"
    fi
}

# Function to preview theme
preview_theme() {
    local theme_name=$(get_theme_value '.meta.name // "Current Theme"')

    # Show theme info
    local theme_info="Theme: $theme_name
Primary BG: $(get_theme_value '.colors.primary.bg_primary')
Accent: $(get_theme_value '.colors.cyberpunk.neon_cyan')
Font: $(get_theme_value '.typography.font_primary')
Border Width: $(get_theme_value '.spacing.border_width')px
Rounding: $(get_theme_value '.spacing.rounding')px"

    echo "$theme_info" | rofi -dmenu -p "👁️ Theme Preview" \
        -theme "$ROFI_THEME" -no-custom -markup-rows
}

# Main function
main() {
    if ! check_dependencies; then
        exit 1
    fi

    case "${1:-menu}" in
        "menu")
            show_theme_editor
            ;;
        "colors")
            show_color_categories
            ;;
        "typography")
            edit_typography
            ;;
        "spacing")
            edit_spacing
            ;;
        "effects")
            edit_effects
            ;;
        "apply")
            apply_theme_changes
            ;;
        *)
            echo "🎨 Visual Theme Editor"
            echo ""
            echo "Usage: $0 {menu|colors|typography|spacing|effects|apply}"
            echo ""
            echo "Commands:"
            echo "  menu        - Show main theme editor menu"
            echo "  colors      - Edit color palette"
            echo "  typography  - Edit fonts and sizes"
            echo "  spacing     - Edit spacing and layout"
            echo "  effects     - Edit visual effects"
            echo "  apply       - Apply theme changes"
            ;;
    esac
}

# Run main function
main "$@"
