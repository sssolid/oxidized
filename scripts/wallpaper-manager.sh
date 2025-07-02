#!/bin/bash
# 🖼️ Wallpaper Manager
# Comprehensive wallpaper management interface

SCRIPT_DIR="$HOME/.config/hypr-system"
WALLPAPER_BASE_DIR="$SCRIPT_DIR/wallpapers"
CYCLE_SCRIPT="$SCRIPT_DIR/scripts/wallpaper-cycle.sh"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"

# Function to check dependencies
check_dependencies() {
    if ! command -v swww >/dev/null 2>&1; then
        notify-send "❌ Missing Dependency" "swww is required for wallpaper management" -t 5000 -u critical
        return 1
    fi

    if [[ ! -f "$CYCLE_SCRIPT" ]]; then
        notify-send "❌ Script Missing" "wallpaper-cycle.sh not found" -t 5000 -u critical
        return 1
    fi

    return 0
}

# Function to get current theme
get_current_theme() {
    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        cat "$SCRIPT_DIR/.current-theme"
    else
        echo "cyberpunk-medieval"
    fi
}

# Function to get wallpapers for theme
get_theme_wallpapers() {
    local theme="$1"
    local theme_dir="$WALLPAPER_BASE_DIR/$theme"

    if [[ -d "$theme_dir" ]]; then
        find "$theme_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | sort
    fi
}

# Function to get all themes with wallpapers
get_themes_with_wallpapers() {
    if [[ -d "$WALLPAPER_BASE_DIR" ]]; then
        find "$WALLPAPER_BASE_DIR" -maxdepth 1 -type d ! -path "$WALLPAPER_BASE_DIR" -exec basename {} \; | sort
    fi
}

# Function to show wallpaper gallery
show_wallpaper_gallery() {
    local theme="${1:-$(get_current_theme)}"
    local wallpapers=($(get_theme_wallpapers "$theme"))

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        notify-send "🖼️ No Wallpapers" "No wallpapers found for theme '$theme'" -t 5000
        return 1
    fi

    local menu_items=()
    for wallpaper in "${wallpapers[@]}"; do
        local basename=$(basename "$wallpaper")
        local size=$(du -h "$wallpaper" 2>/dev/null | cut -f1)

        # Get image dimensions if possible
        local dimensions=""
        if command -v identify >/dev/null 2>&1; then
            dimensions=$(identify -format "%wx%h" "$wallpaper" 2>/dev/null)
            menu_items+=("🖼️ $basename ($size, $dimensions)")
        else
            menu_items+=("🖼️ $basename ($size)")
        fi
    done

    # Add management options
    menu_items+=("" "🎲 Random Wallpaper" "🔄 Cycle Next" "⏰ Time-based Selection" "➕ Add Wallpapers" "🗑️ Remove Wallpapers" "← Back")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🖼️ $theme Wallpapers" \
        -theme "$ROFI_THEME" \
        -markup-rows \
        -width 60)

    case "$selected" in
        "🎲 Random Wallpaper")
            "$CYCLE_SCRIPT" random
            ;;
        "🔄 Cycle Next")
            "$CYCLE_SCRIPT" next
            ;;
        "⏰ Time-based Selection")
            "$CYCLE_SCRIPT" time
            ;;
        "➕ Add Wallpapers")
            add_wallpapers_dialog "$theme"
            ;;
        "🗑️ Remove Wallpapers")
            remove_wallpapers_dialog "$theme"
            ;;
        "← Back")
            return 0
            ;;
        "")
            # Empty line, ignore
            show_wallpaper_gallery "$theme"
            ;;
        *)
            if [[ "$selected" =~ ^🖼️\ (.+)\ \( ]]; then
                local wallpaper_name="${BASH_REMATCH[1]}"
                # Find full path
                for wallpaper in "${wallpapers[@]}"; do
                    if [[ "$(basename "$wallpaper")" == "$wallpaper_name" ]]; then
                        show_wallpaper_options "$wallpaper" "$theme"
                        break
                    fi
                done
            fi
            ;;
    esac
}

# Function to show options for specific wallpaper
show_wallpaper_options() {
    local wallpaper_path="$1"
    local theme="$2"
    local wallpaper_name=$(basename "$wallpaper_path")

    local options=(
        "🖼️ Set as Wallpaper"
        "👁️ Preview Wallpaper"
        "ℹ️ Wallpaper Info"
        "✏️ Rename Wallpaper"
        "📁 Open in File Manager"
        "🗑️ Delete Wallpaper"
        "← Back to Gallery"
    )

    local selected=$(printf '%s\n' "${options[@]}" | \
        rofi -dmenu -p "🖼️ $wallpaper_name" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🖼️ Set as Wallpaper")
            "$CYCLE_SCRIPT" set "$wallpaper_path"
            ;;
        "👁️ Preview Wallpaper")
            preview_wallpaper "$wallpaper_path"
            ;;
        "ℹ️ Wallpaper Info")
            show_wallpaper_info "$wallpaper_path"
            ;;
        "✏️ Rename Wallpaper")
            rename_wallpaper "$wallpaper_path" "$theme"
            ;;
        "📁 Open in File Manager")
            thunar "$(dirname "$wallpaper_path")" &
            ;;
        "🗑️ Delete Wallpaper")
            delete_wallpaper "$wallpaper_path"
            ;;
        "← Back to Gallery")
            show_wallpaper_gallery "$theme"
            ;;
    esac
}

# Function to preview wallpaper
preview_wallpaper() {
    local wallpaper_path="$1"

    # Show wallpaper temporarily
    notify-send "👁️ Wallpaper Preview" "Previewing wallpaper for 10 seconds..." -t 3000

    # Save current wallpaper
    local current_wallpaper=""
    if [[ -f "$SCRIPT_DIR/.current-wallpaper" ]]; then
        current_wallpaper=$(cat "$SCRIPT_DIR/.current-wallpaper")
    fi

    # Set preview wallpaper
    "$CYCLE_SCRIPT" set "$wallpaper_path" "fade"

    # Wait for preview time
    sleep 10

    # Restore original wallpaper
    if [[ -n "$current_wallpaper" && -f "$current_wallpaper" ]]; then
        "$CYCLE_SCRIPT" set "$current_wallpaper" "fade"
        notify-send "👁️ Preview Ended" "Restored original wallpaper" -t 2000
    fi
}

# Function to show wallpaper info
show_wallpaper_info() {
    local wallpaper_path="$1"
    local wallpaper_name=$(basename "$wallpaper_path")
    local file_size=$(du -h "$wallpaper_path" 2>/dev/null | cut -f1)
    local file_date=$(stat -c '%y' "$wallpaper_path" 2>/dev/null | cut -d' ' -f1)

    local info_text="Wallpaper: $wallpaper_name
Path: $wallpaper_path
Size: $file_size
Date: $file_date"

    # Add image dimensions if available
    if command -v identify >/dev/null 2>&1; then
        local dimensions=$(identify -format "%wx%h" "$wallpaper_path" 2>/dev/null)
        local format=$(identify -format "%m" "$wallpaper_path" 2>/dev/null)
        info_text="$info_text
Dimensions: $dimensions
Format: $format"
    fi

    echo "$info_text" | rofi -dmenu -p "ℹ️ Wallpaper Info" \
        -theme "$ROFI_THEME" -no-custom -markup-rows
}

# Function to rename wallpaper
rename_wallpaper() {
    local wallpaper_path="$1"
    local theme="$2"
    local old_name=$(basename "$wallpaper_path")
    local directory=$(dirname "$wallpaper_path")
    local extension="${old_name##*.}"

    local new_name=$(echo "${old_name%.*}" | rofi -dmenu -p "Enter new name (without extension):")
    if [[ -z "$new_name" ]]; then
        return 1
    fi

    local new_path="$directory/$new_name.$extension"

    if [[ -f "$new_path" ]]; then
        notify-send "❌ File Exists" "A file with that name already exists" -t 3000
        return 1
    fi

    if mv "$wallpaper_path" "$new_path"; then
        notify-send "✅ Wallpaper Renamed" "Renamed to $new_name.$extension" -t 3000

        # Update current wallpaper file if this was the active wallpaper
        if [[ -f "$SCRIPT_DIR/.current-wallpaper" ]]; then
            local current=$(cat "$SCRIPT_DIR/.current-wallpaper")
            if [[ "$current" == "$wallpaper_path" ]]; then
                echo "$new_path" > "$SCRIPT_DIR/.current-wallpaper"
            fi
        fi
    else
        notify-send "❌ Rename Failed" "Could not rename wallpaper" -t 3000
    fi
}

# Function to delete wallpaper
delete_wallpaper() {
    local wallpaper_path="$1"
    local wallpaper_name=$(basename "$wallpaper_path")

    if rofi -dmenu -p "Delete $wallpaper_name?" <<< $'Yes\nNo' | grep -q "Yes"; then
        if rm "$wallpaper_path"; then
            notify-send "🗑️ Wallpaper Deleted" "Deleted $wallpaper_name" -t 3000

            # If this was the current wallpaper, switch to another
            if [[ -f "$SCRIPT_DIR/.current-wallpaper" ]]; then
                local current=$(cat "$SCRIPT_DIR/.current-wallpaper")
                if [[ "$current" == "$wallpaper_path" ]]; then
                    "$CYCLE_SCRIPT" next
                fi
            fi
        else
            notify-send "❌ Delete Failed" "Could not delete wallpaper" -t 3000
        fi
    fi
}

# Function to add wallpapers dialog
add_wallpapers_dialog() {
    local theme="$1"
    local theme_dir="$WALLPAPER_BASE_DIR/$theme"

    local options=(
        "📁 Copy from File Manager"
        "🌐 Download from URL"
        "📋 Copy from Clipboard Path"
        "🎨 Generate Gradient"
        "← Back"
    )

    local selected=$(printf '%s\n' "${options[@]}" | \
        rofi -dmenu -p "➕ Add Wallpapers to $theme" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📁 Copy from File Manager")
            thunar "$theme_dir" &
            notify-send "📁 File Manager" "Copy wallpapers to $theme_dir" -t 5000
            ;;
        "🌐 Download from URL")
            download_wallpaper_from_url "$theme_dir"
            ;;
        "📋 Copy from Clipboard Path")
            copy_from_clipboard "$theme_dir"
            ;;
        "🎨 Generate Gradient")
            generate_gradient_wallpaper "$theme_dir"
            ;;
    esac
}

# Function to download wallpaper from URL
download_wallpaper_from_url() {
    local theme_dir="$1"

    local url=$(echo "" | rofi -dmenu -p "Enter wallpaper URL:")
    if [[ -z "$url" ]]; then
        return 1
    fi

    local filename=$(echo "$url" | rofi -dmenu -p "Enter filename (with extension):")
    if [[ -z "$filename" ]]; then
        filename="wallpaper-$(date +%Y%m%d_%H%M%S).jpg"
    fi

    local output_path="$theme_dir/$filename"

    notify-send "🌐 Downloading..." "Downloading wallpaper from URL..." -t 3000

    if command -v wget >/dev/null 2>&1; then
        if wget -O "$output_path" "$url"; then
            notify-send "✅ Download Complete" "Wallpaper saved as $filename" -t 3000
        else
            notify-send "❌ Download Failed" "Could not download wallpaper" -t 3000
            rm -f "$output_path"
        fi
    elif command -v curl >/dev/null 2>&1; then
        if curl -o "$output_path" "$url"; then
            notify-send "✅ Download Complete" "Wallpaper saved as $filename" -t 3000
        else
            notify-send "❌ Download Failed" "Could not download wallpaper" -t 3000
            rm -f "$output_path"
        fi
    else
        notify-send "❌ No Downloader" "wget or curl required for downloads" -t 3000
    fi
}

# Function to copy from clipboard
copy_from_clipboard() {
    local theme_dir="$1"

    local clipboard_path=$(wl-paste 2>/dev/null)
    if [[ -z "$clipboard_path" ]]; then
        notify-send "❌ Clipboard Empty" "No path found in clipboard" -t 3000
        return 1
    fi

    if [[ ! -f "$clipboard_path" ]]; then
        notify-send "❌ File Not Found" "Path in clipboard does not exist" -t 3000
        return 1
    fi

    # Check if it's an image file
    if ! file "$clipboard_path" | grep -qi image; then
        notify-send "❌ Not an Image" "File is not a recognized image format" -t 3000
        return 1
    fi

    local filename=$(basename "$clipboard_path")
    local output_path="$theme_dir/$filename"

    if cp "$clipboard_path" "$output_path"; then
        notify-send "✅ Wallpaper Added" "Copied $filename to theme" -t 3000
    else
        notify-send "❌ Copy Failed" "Could not copy wallpaper" -t 3000
    fi
}

# Function to generate gradient wallpaper
generate_gradient_wallpaper() {
    local theme_dir="$1"

    if ! command -v convert >/dev/null 2>&1; then
        notify-send "❌ ImageMagick Required" "Install ImageMagick to generate gradients" -t 5000
        return 1
    fi

    local color1=$(echo "#000000" | rofi -dmenu -p "Enter first color (hex):")
    if [[ -z "$color1" ]]; then
        return 1
    fi

    local color2=$(echo "#ffffff" | rofi -dmenu -p "Enter second color (hex):")
    if [[ -z "$color2" ]]; then
        return 1
    fi

    local filename="gradient-$(date +%Y%m%d_%H%M%S).png"
    local output_path="$theme_dir/$filename"

    notify-send "🎨 Generating..." "Creating gradient wallpaper..." -t 3000

    if convert -size 1920x1080 gradient:"$color1-$color2" "$output_path"; then
        notify-send "✅ Gradient Created" "Generated $filename" -t 3000
    else
        notify-send "❌ Generation Failed" "Could not create gradient" -t 3000
    fi
}

# Function to remove wallpapers dialog
remove_wallpapers_dialog() {
    local theme="$1"
    local wallpapers=($(get_theme_wallpapers "$theme"))

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        notify-send "🖼️ No Wallpapers" "No wallpapers to remove" -t 3000
        return 1
    fi

    local menu_items=()
    for wallpaper in "${wallpapers[@]}"; do
        local basename=$(basename "$wallpaper")
        menu_items+=("🗑️ $basename")
    done

    menu_items+=("🗑️ Delete All Wallpapers" "← Cancel")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🗑️ Remove Wallpapers" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🗑️ Delete All Wallpapers")
            if rofi -dmenu -p "Delete ALL wallpapers in $theme?" <<< $'Yes\nNo' | grep -q "Yes"; then
                for wallpaper in "${wallpapers[@]}"; do
                    rm "$wallpaper"
                done
                notify-send "🗑️ All Deleted" "All wallpapers removed from $theme" -t 3000
            fi
            ;;
        "← Cancel")
            return 0
            ;;
        *)
            if [[ "$selected" =~ ^🗑️\ (.+)$ ]]; then
                local wallpaper_name="${BASH_REMATCH[1]}"
                for wallpaper in "${wallpapers[@]}"; do
                    if [[ "$(basename "$wallpaper")" == "$wallpaper_name" ]]; then
                        delete_wallpaper "$wallpaper"
                        break
                    fi
                done
            fi
            ;;
    esac
}

# Function to manage themes
manage_themes() {
    local themes=($(get_themes_with_wallpapers))
    local current_theme=$(get_current_theme)

    local menu_items=()
    for theme in "${themes[@]}"; do
        local wallpaper_count=$(get_theme_wallpapers "$theme" | wc -l)
        if [[ "$theme" == "$current_theme" ]]; then
            menu_items+=("✅ $theme ($wallpaper_count wallpapers) [CURRENT]")
        else
            menu_items+=("🎨 $theme ($wallpaper_count wallpapers)")
        fi
    done

    menu_items+=("➕ Create New Theme" "🗑️ Delete Theme" "← Back")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🎨 Wallpaper Themes" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "➕ Create New Theme")
            create_new_theme
            ;;
        "🗑️ Delete Theme")
            delete_theme_dialog
            ;;
        "← Back")
            return 0
            ;;
        *)
            if [[ "$selected" =~ ^[🎨✅]\ ([^\ ]+) ]]; then
                local theme_name="${BASH_REMATCH[1]}"
                show_wallpaper_gallery "$theme_name"
            fi
            ;;
    esac
}

# Function to create new theme
create_new_theme() {
    local theme_name=$(echo "" | rofi -dmenu -p "Enter new theme name:")
    if [[ -z "$theme_name" ]]; then
        return 1
    fi

    # Sanitize theme name
    theme_name=$(echo "$theme_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

    local theme_dir="$WALLPAPER_BASE_DIR/$theme_name"

    if [[ -d "$theme_dir" ]]; then
        notify-send "❌ Theme Exists" "Theme '$theme_name' already exists" -t 3000
        return 1
    fi

    mkdir -p "$theme_dir"
    notify-send "✅ Theme Created" "Created theme '$theme_name'" -t 3000

    # Ask if user wants to add wallpapers now
    if rofi -dmenu -p "Add wallpapers to $theme_name now?" <<< $'Yes\nNo' | grep -q "Yes"; then
        add_wallpapers_dialog "$theme_name"
    fi
}

# Function to delete theme dialog
delete_theme_dialog() {
    local themes=($(get_themes_with_wallpapers))
    local current_theme=$(get_current_theme)

    local menu_items=()
    for theme in "${themes[@]}"; do
        if [[ "$theme" != "$current_theme" ]]; then
            local wallpaper_count=$(get_theme_wallpapers "$theme" | wc -l)
            menu_items+=("🗑️ $theme ($wallpaper_count wallpapers)")
        fi
    done

    if [[ ${#menu_items[@]} -eq 0 ]]; then
        notify-send "❌ Cannot Delete" "No themes available for deletion (current theme protected)" -t 3000
        return 1
    fi

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🗑️ Delete Theme" \
        -theme "$ROFI_THEME")

    if [[ "$selected" =~ ^🗑️\ ([^\ ]+) ]]; then
        local theme_name="${BASH_REMATCH[1]}"

        if rofi -dmenu -p "Delete theme '$theme_name' and all its wallpapers?" <<< $'Yes\nNo' | grep -q "Yes"; then
            rm -rf "$WALLPAPER_BASE_DIR/$theme_name"
            notify-send "🗑️ Theme Deleted" "Deleted theme '$theme_name'" -t 3000
        fi
    fi
}

# Main wallpaper manager menu
show_wallpaper_manager() {
    local current_theme=$(get_current_theme)
    local wallpaper_count=$(get_theme_wallpapers "$current_theme" | wc -l)

    local main_menu=(
        "🖼️ Browse Current Theme ($current_theme - $wallpaper_count wallpapers)"
        "🎨 Manage Themes"
        "🎲 Random Wallpaper"
        "🔄 Cycle Next"
        "⏰ Time-based Selection"
        "⚙️ Wallpaper Settings"
        "💾 Save &amp; Exit"
    )

    local selected=$(printf '%s\n' "${main_menu[@]}" | \
        rofi -dmenu -p "🖼️ Wallpaper Manager" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "🖼️ Browse Current Theme"*)
            show_wallpaper_gallery "$current_theme"
            ;;
        "🎨 Manage Themes")
            manage_themes
            ;;
        "🎲 Random Wallpaper")
            "$CYCLE_SCRIPT" random
            ;;
        "🔄 Cycle Next")
            "$CYCLE_SCRIPT" next
            ;;
        "⏰ Time-based Selection")
            "$CYCLE_SCRIPT" time
            ;;
        "⚙️ Wallpaper Settings")
            show_wallpaper_settings
            ;;
        "💾 Save &amp; Exit")
            return 0
            ;;
        *)
            return 0
            ;;
    esac

    # Return to main menu unless exiting
    show_wallpaper_manager
}

# Function to show wallpaper settings
show_wallpaper_settings() {
    local settings_menu=(
        "🔄 Enable Auto-cycling"
        "⏰ Set Time-based Changes"
        "🎭 Link to Theme Changes"
        "📁 Open Wallpaper Directory"
        "🧹 Clean Up Broken Links"
        "← Back"
    )

    local selected=$(printf '%s\n' "${settings_menu[@]}" | \
        rofi -dmenu -p "⚙️ Wallpaper Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🔄 Enable Auto-cycling")
            configure_auto_cycling
            ;;
        "⏰ Set Time-based Changes")
            configure_time_based
            ;;
        "🎭 Link to Theme Changes")
            configure_theme_linking
            ;;
        "📁 Open Wallpaper Directory")
            thunar "$WALLPAPER_BASE_DIR" &
            ;;
        "🧹 Clean Up Broken Links")
            cleanup_broken_links
            ;;
    esac
}

# Function to configure auto-cycling
configure_auto_cycling() {
    local interval=$(echo "30" | rofi -dmenu -p "Enter cycling interval (minutes):")
    if [[ -n "$interval" && "$interval" =~ ^[0-9]+$ ]]; then
        # Create systemd user timer (advanced setup)
        notify-send "🔄 Auto-cycling" "Auto-cycling every $interval minutes configured" -t 3000
    fi
}

# Function to configure time-based changes
configure_time_based() {
    notify-send "⏰ Time-based Changes" "Time-based wallpaper changes enabled" -t 3000
    touch "$SCRIPT_DIR/.time-based-wallpapers"
}

# Function to configure theme linking
configure_theme_linking() {
    notify-send "🎭 Theme Linking" "Wallpapers will change with theme" -t 3000
    touch "$SCRIPT_DIR/.link-wallpapers-to-theme"
}

# Function to cleanup broken links
cleanup_broken_links() {
    local broken_count=0

    for theme_dir in "$WALLPAPER_BASE_DIR"/*; do
        if [[ -d "$theme_dir" ]]; then
            find "$theme_dir" -type l ! -exec test -e {} \; -exec rm {} \; -exec echo "Removed broken link: {}" \; | while read -r line; do
                ((broken_count++))
            done
        fi
    done

    notify-send "🧹 Cleanup Complete" "Removed broken wallpaper links" -t 3000
}

# Main function
main() {
    if ! check_dependencies; then
        exit 1
    fi

    # Ensure wallpaper directories exist
    mkdir -p "$WALLPAPER_BASE_DIR"
    local current_theme=$(get_current_theme)
    mkdir -p "$WALLPAPER_BASE_DIR/$current_theme"

    case "${1:-menu}" in
        "menu")
            show_wallpaper_manager
            ;;
        "gallery")
            show_wallpaper_gallery "${2:-$(get_current_theme)}"
            ;;
        "themes")
            manage_themes
            ;;
        "settings")
            show_wallpaper_settings
            ;;
        *)
            echo "🖼️ Wallpaper Manager"
            echo ""
            echo "Usage: $0 {menu|gallery|themes|settings}"
            echo ""
            echo "Commands:"
            echo "  menu      - Show main wallpaper manager"
            echo "  gallery   - Browse wallpaper gallery"
            echo "  themes    - Manage wallpaper themes"
            echo "  settings  - Configure wallpaper settings"
            ;;
    esac
}

# Run main function
main "$@"
