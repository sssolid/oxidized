#!/bin/bash
# 📥 Theme Import Manager
# Import themes from various sources and formats

SCRIPT_DIR="$HOME/.config/hypr-system"
THEMES_DIR="$SCRIPT_DIR/themes"
THEME_CONFIG="$SCRIPT_DIR/core/theme-config.json"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"
GREEN="#39ff14"
CRIMSON="#dc143c"

# Function to check dependencies
check_dependencies() {
    local missing_deps=()

    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing_deps+=("curl or wget")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        notify-send "❌ Missing Dependencies" "Required: ${missing_deps[*]}" -t 5000 -u critical
        return 1
    fi

    return 0
}

# Function to validate theme JSON
validate_theme_json() {
    local theme_file="$1"

    if ! jq empty "$theme_file" 2>/dev/null; then
        return 1
    fi

    # Check for required fields
    local required_fields=(".meta.name" ".colors" ".typography" ".spacing")

    for field in "${required_fields[@]}"; do
        if ! jq -e "$field" "$theme_file" >/dev/null 2>&1; then
            echo "Missing required field: $field"
            return 1
        fi
    done

    return 0
}

# Function to sanitize theme name
sanitize_theme_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g'
}

# Function to import from file
import_from_file() {
    local file_path=$(echo "" | rofi -dmenu -p "📁 Enter path to theme file:")

    if [[ -z "$file_path" || ! -f "$file_path" ]]; then
        notify-send "❌ File Not Found" "Theme file not found or invalid path" -t 3000
        return 1
    fi

    local file_extension="${file_path##*.}"

    case "$file_extension" in
        "json")
            import_json_theme "$file_path"
            ;;
        "tar.gz"|"tgz")
            import_theme_package "$file_path"
            ;;
        "zip")
            import_zip_theme "$file_path"
            ;;
        *)
            notify-send "❌ Unsupported Format" "Supported formats: .json, .tar.gz, .zip" -t 3000
            return 1
            ;;
    esac
}

# Function to import JSON theme
import_json_theme() {
    local theme_file="$1"

    # Validate JSON
    local validation_result=$(validate_theme_json "$theme_file")
    if [[ $? -ne 0 ]]; then
        notify-send "❌ Invalid Theme" "Theme validation failed: $validation_result" -t 5000
        return 1
    fi

    # Get theme name
    local theme_name=$(jq -r '.meta.name // "Unknown Theme"' "$theme_file")
    local theme_id=$(sanitize_theme_name "$theme_name")

    # Ask user for confirmation
    if ! rofi -dmenu -p "📥 Import theme '$theme_name'?" <<< $'Yes\nNo' | grep -q "Yes"; then
        return 0
    fi

    # Check if theme already exists
    local target_file="$THEMES_DIR/$theme_id.json"
    if [[ -f "$target_file" ]]; then
        if ! rofi -dmenu -p "⚠️ Theme '$theme_id' exists. Overwrite?" <<< $'Yes\nNo' | grep -q "Yes"; then
            return 0
        fi
    fi

    # Copy theme file
    mkdir -p "$THEMES_DIR"
    cp "$theme_file" "$target_file"

    # Update theme metadata
    local temp_file=$(mktemp)
    jq --arg id "$theme_id" --arg imported "$(date)" \
       '.meta.theme_id = $id | .meta.imported_date = $imported' \
       "$target_file" > "$temp_file" && mv "$temp_file" "$target_file"

    notify-send "✅ Theme Imported" "Theme '$theme_name' imported as '$theme_id'" -t 3000

    # Ask if user wants to apply the theme
    if rofi -dmenu -p "🎨 Apply imported theme now?" <<< $'Yes\nNo' | grep -q "Yes"; then
        apply_imported_theme "$theme_id"
    fi
}

# Function to import theme package (tar.gz)
import_theme_package() {
    local package_file="$1"

    # Create temporary directory
    local temp_dir=$(mktemp -d)

    # Extract package
    if ! tar -xzf "$package_file" -C "$temp_dir" 2>/dev/null; then
        notify-send "❌ Extraction Failed" "Could not extract theme package" -t 3000
        rm -rf "$temp_dir"
        return 1
    fi

    # Look for theme.json or similar
    local theme_json=""
    for json_file in "$temp_dir"/*.json "$temp_dir"/*/theme.json "$temp_dir"/*/theme-config.json; do
        if [[ -f "$json_file" ]]; then
            theme_json="$json_file"
            break
        fi
    done

    if [[ -z "$theme_json" ]]; then
        notify-send "❌ No Theme Config" "No theme configuration found in package" -t 3000
        rm -rf "$temp_dir"
        return 1
    fi

    # Import the JSON theme
    import_json_theme "$theme_json"

    # Check for additional assets (wallpapers, etc.)
    import_theme_assets "$temp_dir"

    # Cleanup
    rm -rf "$temp_dir"
}

# Function to import zip theme
import_zip_theme() {
    local zip_file="$1"

    if ! command -v unzip >/dev/null 2>&1; then
        notify-send "❌ Missing unzip" "unzip command required for .zip files" -t 3000
        return 1
    fi

    # Create temporary directory
    local temp_dir=$(mktemp -d)

    # Extract zip
    if ! unzip -q "$zip_file" -d "$temp_dir" 2>/dev/null; then
        notify-send "❌ Extraction Failed" "Could not extract zip file" -t 3000
        rm -rf "$temp_dir"
        return 1
    fi

    # Look for theme configuration
    local theme_json=""
    for json_file in "$temp_dir"/*.json "$temp_dir"/*/theme.json "$temp_dir"/*/config.json; do
        if [[ -f "$json_file" ]]; then
            theme_json="$json_file"
            break
        fi
    done

    if [[ -z "$theme_json" ]]; then
        notify-send "❌ No Theme Config" "No theme configuration found in zip" -t 3000
        rm -rf "$temp_dir"
        return 1
    fi

    # Import the JSON theme
    import_json_theme "$theme_json"

    # Import additional assets
    import_theme_assets "$temp_dir"

    # Cleanup
    rm -rf "$temp_dir"
}

# Function to import theme assets
import_theme_assets() {
    local source_dir="$1"

    # Look for wallpapers
    local wallpaper_dirs=("$source_dir/wallpapers" "$source_dir/backgrounds" "$source_dir/images")

    for wallpaper_dir in "${wallpaper_dirs[@]}"; do
        if [[ -d "$wallpaper_dir" ]]; then
            local theme_id=$(basename "$THEMES_DIR"/*.json 2>/dev/null | head -1 | sed 's/.json$//')
            if [[ -n "$theme_id" ]]; then
                local target_wallpaper_dir="$SCRIPT_DIR/wallpapers/$theme_id"
                mkdir -p "$target_wallpaper_dir"

                # Copy wallpapers
                find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
                    -exec cp {} "$target_wallpaper_dir/" \; 2>/dev/null

                local wallpaper_count=$(find "$target_wallpaper_dir" -type f | wc -l)
                if [[ $wallpaper_count -gt 0 ]]; then
                    notify-send "🖼️ Wallpapers Imported" "Imported $wallpaper_count wallpapers" -t 3000
                fi
            fi
            break
        fi
    done
}

# Function to import from URL
import_from_url() {
    local url=$(echo "" | rofi -dmenu -p "🌐 Enter theme URL:")

    if [[ -z "$url" ]]; then
        return 1
    fi

    # Validate URL
    if [[ ! "$url" =~ ^https?:// ]]; then
        notify-send "❌ Invalid URL" "URL must start with http:// or https://" -t 3000
        return 1
    fi

    notify-send "🌐 Downloading..." "Downloading theme from URL..." -t 3000

    # Create temporary file
    local temp_file=$(mktemp --suffix=.theme)

    # Download file
    if command -v curl >/dev/null 2>&1; then
        if ! curl -sSL "$url" -o "$temp_file"; then
            notify-send "❌ Download Failed" "Could not download theme from URL" -t 3000
            rm -f "$temp_file"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$url" -O "$temp_file"; then
            notify-send "❌ Download Failed" "Could not download theme from URL" -t 3000
            rm -f "$temp_file"
            return 1
        fi
    fi

    # Determine file type and import
    local file_type=$(file -b --mime-type "$temp_file")

    case "$file_type" in
        "application/json"|"text/plain")
            import_json_theme "$temp_file"
            ;;
        "application/gzip"|"application/x-gzip")
            import_theme_package "$temp_file"
            ;;
        "application/zip")
            import_zip_theme "$temp_file"
            ;;
        *)
            notify-send "❌ Unknown Format" "Downloaded file format not recognized" -t 3000
            ;;
    esac

    # Cleanup
    rm -f "$temp_file"
}

# Function to import from clipboard
import_from_clipboard() {
    local clipboard_content=$(wl-paste 2>/dev/null)

    if [[ -z "$clipboard_content" ]]; then
        notify-send "❌ Clipboard Empty" "No content found in clipboard" -t 3000
        return 1
    fi

    # Check if it's a URL
    if [[ "$clipboard_content" =~ ^https?:// ]]; then
        notify-send "🌐 URL Detected" "Downloading theme from clipboard URL..." -t 2000
        import_from_url_direct "$clipboard_content"
        return
    fi

    # Check if it's JSON
    if echo "$clipboard_content" | jq empty 2>/dev/null; then
        # Create temporary file
        local temp_file=$(mktemp --suffix=.json)
        echo "$clipboard_content" > "$temp_file"

        import_json_theme "$temp_file"
        rm -f "$temp_file"
    else
        notify-send "❌ Invalid Content" "Clipboard content is not valid JSON or URL" -t 3000
    fi
}

# Function to import from URL directly
import_from_url_direct() {
    local url="$1"

    notify-send "🌐 Downloading..." "Downloading theme from URL..." -t 3000

    local temp_file=$(mktemp --suffix=.theme)

    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$url" -o "$temp_file"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$temp_file"
    else
        notify-send "❌ No Downloader" "curl or wget required for URL downloads" -t 3000
        return 1
    fi

    # Import based on content
    if jq empty "$temp_file" 2>/dev/null; then
        import_json_theme "$temp_file"
    else
        import_theme_package "$temp_file"
    fi

    rm -f "$temp_file"
}

# Function to import from Git repository
import_from_git() {
    if ! command -v git >/dev/null 2>&1; then
        notify-send "❌ Git Not Found" "git command required for repository imports" -t 3000
        return 1
    fi

    local git_url=$(echo "" | rofi -dmenu -p "📦 Enter Git repository URL:")

    if [[ -z "$git_url" ]]; then
        return 1
    fi

    notify-send "📦 Cloning..." "Cloning theme repository..." -t 3000

    # Create temporary directory
    local temp_dir=$(mktemp -d)

    # Clone repository
    if ! git clone --depth 1 "$git_url" "$temp_dir/repo" 2>/dev/null; then
        notify-send "❌ Clone Failed" "Could not clone repository" -t 3000
        rm -rf "$temp_dir"
        return 1
    fi

    # Look for theme files
    local theme_files=($(find "$temp_dir/repo" -name "*.json" -o -name "theme.json" -o -name "config.json"))

    if [[ ${#theme_files[@]} -eq 0 ]]; then
        notify-send "❌ No Theme Found" "No theme configuration found in repository" -t 3000
        rm -rf "$temp_dir"
        return 1
    fi

    # If multiple theme files, let user choose
    local theme_file
    if [[ ${#theme_files[@]} -eq 1 ]]; then
        theme_file="${theme_files[0]}"
    else
        local theme_names=()
        for file in "${theme_files[@]}"; do
            theme_names+=("$(basename "$file")")
        done

        local selected_theme=$(printf '%s\n' "${theme_names[@]}" | \
            rofi -dmenu -p "📦 Select theme file:")

        if [[ -n "$selected_theme" ]]; then
            theme_file="$temp_dir/repo/$selected_theme"
        else
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # Import the selected theme
    import_json_theme "$theme_file"

    # Import additional assets
    import_theme_assets "$temp_dir/repo"

    # Cleanup
    rm -rf "$temp_dir"
}

# Function to import from theme gallery
import_from_gallery() {
    local gallery_themes=(
        "cyberpunk-neo|Neo Cyberpunk|https://example.com/themes/cyberpunk-neo.json"
        "medieval-dark|Dark Medieval|https://example.com/themes/medieval-dark.json"
        "synthwave-80s|80s Synthwave|https://example.com/themes/synthwave-80s.json"
        "matrix-green|Matrix Green|https://example.com/themes/matrix-green.json"
        "neon-city|Neon City|https://example.com/themes/neon-city.json"
    )

    local menu_items=()
    for theme in "${gallery_themes[@]}"; do
        IFS='|' read -r theme_id theme_name theme_url <<< "$theme"
        menu_items+=("🎨 $theme_name")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🎨 Theme Gallery" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected" ]]; then
        local theme_name="${selected#🎨 }"

        # Find the corresponding URL
        for theme in "${gallery_themes[@]}"; do
            IFS='|' read -r theme_id theme_display theme_url <<< "$theme"
            if [[ "$theme_display" == "$theme_name" ]]; then
                import_from_url_direct "$theme_url"
                break
            fi
        done
    fi
}

# Function to apply imported theme
apply_imported_theme() {
    local theme_id="$1"
    local theme_file="$THEMES_DIR/$theme_id.json"

    if [[ ! -f "$theme_file" ]]; then
        notify-send "❌ Theme Not Found" "Imported theme file not found" -t 3000
        return 1
    fi

    # Backup current theme
    if [[ -f "$THEME_CONFIG" ]]; then
        cp "$THEME_CONFIG" "$SCRIPT_DIR/backups/theme-backup-$(date +%Y%m%d_%H%M%S).json"
    fi

    # Apply imported theme
    cp "$theme_file" "$THEME_CONFIG"
    echo "$theme_id" > "$SCRIPT_DIR/.current-theme"

    # Regenerate configuration
    if [[ -f "$SCRIPT_DIR/generators/apply-theme.py" ]]; then
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py
        notify-send "✅ Theme Applied" "Imported theme '$theme_id' is now active" -t 3000
    else
        notify-send "⚠️ Manual Restart Required" "Please restart Hyprland to see changes" -t 5000
    fi
}

# Function to show import preview
show_import_preview() {
    local theme_file="$1"

    if [[ ! -f "$theme_file" ]]; then
        return 1
    fi

    local theme_name=$(jq -r '.meta.name // "Unknown"' "$theme_file")
    local theme_author=$(jq -r '.meta.author // "Unknown"' "$theme_file")
    local theme_version=$(jq -r '.meta.version // "Unknown"' "$theme_file")
    local theme_description=$(jq -r '.meta.description // "No description"' "$theme_file")

    local primary_bg=$(jq -r '.colors.primary.bg_primary // "#000000"' "$theme_file")
    local accent_color=$(jq -r '.colors.cyberpunk.neon_cyan // "#00ffff"' "$theme_file")
    local font_family=$(jq -r '.typography.font_primary // "Unknown"' "$theme_file")

    local preview_info="🎨 THEME PREVIEW

Name: $theme_name
Author: $theme_author
Version: $theme_version
Description: $theme_description

Colors:
  Background: $primary_bg
  Accent: $accent_color
  Font: $font_family

This preview shows basic theme information.
Import to see the full theme in action."

    echo "$preview_info" | rofi -dmenu -p "👁️ Theme Preview" \
        -theme "$ROFI_THEME" -no-custom -width 60
}

# Main import manager menu
show_import_manager() {
    local main_menu=(
        "📁 Import from File"
        "🌐 Import from URL"
        "📋 Import from Clipboard"
        "📦 Import from Git Repository"
        "🎨 Browse Theme Gallery"
        "👁️ Preview Theme File"
        "📋 List Imported Themes"
        "🗑️ Remove Imported Theme"
        "💾 Save & Exit"
    )

    local selected=$(printf '%s\n' "${main_menu[@]}" | \
        rofi -dmenu -p "📥 Theme Import Manager" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "📁 Import from File")
            import_from_file
            ;;
        "🌐 Import from URL")
            import_from_url
            ;;
        "📋 Import from Clipboard")
            import_from_clipboard
            ;;
        "📦 Import from Git Repository")
            import_from_git
            ;;
        "🎨 Browse Theme Gallery")
            import_from_gallery
            ;;
        "👁️ Preview Theme File")
            preview_theme_file
            ;;
        "📋 List Imported Themes")
            list_imported_themes
            ;;
        "🗑️ Remove Imported Theme")
            remove_imported_theme
            ;;
        "💾 Save & Exit")
            return 0
            ;;
        *)
            return 0
            ;;
    esac

    # Return to main menu unless exiting
    show_import_manager
}

# Function to preview theme file
preview_theme_file() {
    local theme_file=$(echo "" | rofi -dmenu -p "📁 Enter path to theme file:")

    if [[ -n "$theme_file" && -f "$theme_file" ]]; then
        show_import_preview "$theme_file"
    else
        notify-send "❌ File Not Found" "Theme file not found" -t 3000
    fi
}

# Function to list imported themes
list_imported_themes() {
    if [[ ! -d "$THEMES_DIR" ]]; then
        notify-send "📋 No Themes" "No imported themes found" -t 3000
        return
    fi

    local theme_files=($(find "$THEMES_DIR" -name "*.json" 2>/dev/null))

    if [[ ${#theme_files[@]} -eq 0 ]]; then
        notify-send "📋 No Themes" "No imported themes found" -t 3000
        return
    fi

    local theme_list=""
    for theme_file in "${theme_files[@]}"; do
        local theme_name=$(jq -r '.meta.name // "Unknown"' "$theme_file")
        local theme_id=$(basename "$theme_file" .json)
        theme_list="$theme_list$theme_name ($theme_id)\n"
    done

    echo -e "$theme_list" | rofi -dmenu -p "📋 Imported Themes" \
        -theme "$ROFI_THEME" -no-custom -width 50
}

# Function to remove imported theme
remove_imported_theme() {
    if [[ ! -d "$THEMES_DIR" ]]; then
        notify-send "📋 No Themes" "No imported themes to remove" -t 3000
        return
    fi

    local theme_files=($(find "$THEMES_DIR" -name "*.json" 2>/dev/null))

    if [[ ${#theme_files[@]} -eq 0 ]]; then
        notify-send "📋 No Themes" "No imported themes to remove" -t 3000
        return
    fi

    local menu_items=()
    for theme_file in "${theme_files[@]}"; do
        local theme_name=$(jq -r '.meta.name // "Unknown"' "$theme_file")
        local theme_id=$(basename "$theme_file" .json)
        menu_items+=("🗑️ $theme_name ($theme_id)")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🗑️ Remove Theme" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected" ]]; then
        # Extract theme ID
        local theme_id=$(echo "$selected" | sed 's/.*(\(.*\)).*/\1/')
        local theme_file="$THEMES_DIR/$theme_id.json"

        if rofi -dmenu -p "🗑️ Delete theme '$theme_id'?" <<< $'Yes\nNo' | grep -q "Yes"; then
            rm -f "$theme_file"

            # Also remove associated wallpapers
            local wallpaper_dir="$SCRIPT_DIR/wallpapers/$theme_id"
            if [[ -d "$wallpaper_dir" ]]; then
                rm -rf "$wallpaper_dir"
            fi

            notify-send "🗑️ Theme Removed" "Removed theme '$theme_id'" -t 3000
        fi
    fi
}

# Main function
main() {
    if ! check_dependencies; then
        exit 1
    fi

    # Ensure directories exist
    mkdir -p "$THEMES_DIR" "$SCRIPT_DIR/wallpapers" "$SCRIPT_DIR/backups"

    case "${1:-menu}" in
        "menu")
            show_import_manager
            ;;
        "file")
            import_from_file
            ;;
        "url")
            shift
            import_from_url_direct "$1"
            ;;
        "clipboard")
            import_from_clipboard
            ;;
        "git")
            import_from_git
            ;;
        "gallery")
            import_from_gallery
            ;;
        *)
            echo "📥 Theme Import Manager"
            echo ""
            echo "Usage: $0 {menu|file|url|clipboard|git|gallery}"
            echo ""
            echo "Commands:"
            echo "  menu       - Show import manager interface"
            echo "  file       - Import from local file"
            echo "  url <url>  - Import from URL"
            echo "  clipboard  - Import from clipboard content"
            echo "  git        - Import from Git repository"
            echo "  gallery    - Browse theme gallery"
            ;;
    esac
}

# Run main function
main "$@"
