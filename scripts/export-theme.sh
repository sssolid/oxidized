#!/bin/bash
# 📤 Theme Export Manager
# Export themes in various formats for sharing and distribution

SCRIPT_DIR="$HOME/.config/hypr-system"
THEME_CONFIG="$SCRIPT_DIR/core/theme-config.json"
THEMES_DIR="$SCRIPT_DIR/themes"
EXPORT_DIR="$HOME/Desktop"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"
GREEN="#39ff14"

# Function to check dependencies
check_dependencies() {
    local missing_deps=()

    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi

    if ! command -v tar >/dev/null 2>&1; then
        missing_deps+=("tar")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        notify-send "❌ Missing Dependencies" "Required: ${missing_deps[*]}" -t 5000 -u critical
        return 1
    fi

    return 0
}

# Function to get current theme info
get_current_theme_info() {
    if [[ ! -f "$THEME_CONFIG" ]]; then
        return 1
    fi

    local theme_name=$(jq -r '.meta.name // "Current Theme"' "$THEME_CONFIG")
    local theme_author=$(jq -r '.meta.author // "Unknown"' "$THEME_CONFIG")
    local theme_version=$(jq -r '.meta.version // "1.0"' "$THEME_CONFIG")

    echo "$theme_name|$theme_author|$theme_version"
}

# Function to export as JSON
export_as_json() {
    local export_name="$1"
    local export_file="$EXPORT_DIR/${export_name}.json"

    if [[ ! -f "$THEME_CONFIG" ]]; then
        notify-send "❌ No Theme Config" "Theme configuration not found" -t 3000
        return 1
    fi

    # Add export metadata
    local temp_file=$(mktemp)
    jq --arg exported "$(date)" --arg version "2.0" \
       '.meta.exported_date = $exported | .meta.export_version = $version' \
       "$THEME_CONFIG" > "$temp_file"

    mv "$temp_file" "$export_file"

    notify-send "📤 Theme Exported" "JSON theme exported to: $(basename "$export_file")" -t 3000
    echo "$export_file"
}

# Function to export complete package
export_as_package() {
    local export_name="$1"
    local temp_dir=$(mktemp -d)
    local package_dir="$temp_dir/$export_name"
    local export_file="$EXPORT_DIR/${export_name}.tar.gz"

    mkdir -p "$package_dir"

    # Copy theme configuration
    if [[ -f "$THEME_CONFIG" ]]; then
        cp "$THEME_CONFIG" "$package_dir/theme-config.json"
    else
        notify-send "❌ No Theme Config" "Theme configuration not found" -t 3000
        rm -rf "$temp_dir"
        return 1
    fi

    # Copy wallpapers if they exist
    local current_theme_id=""
    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        current_theme_id=$(cat "$SCRIPT_DIR/.current-theme")
    fi

    local wallpaper_source="$SCRIPT_DIR/wallpapers/$current_theme_id"
    if [[ -d "$wallpaper_source" ]] && [[ -n "$(ls -A "$wallpaper_source" 2>/dev/null)" ]]; then
        mkdir -p "$package_dir/wallpapers"
        cp -r "$wallpaper_source"/* "$package_dir/wallpapers/" 2>/dev/null
        local wallpaper_count=$(find "$package_dir/wallpapers" -type f | wc -l)
        echo "📁 Included $wallpaper_count wallpapers"
    fi

    # Copy custom scripts if any
    local custom_scripts_dir="$SCRIPT_DIR/custom-scripts"
    if [[ -d "$custom_scripts_dir" ]]; then
        mkdir -p "$package_dir/scripts"
        cp -r "$custom_scripts_dir"/* "$package_dir/scripts/" 2>/dev/null
    fi

    # Create package info file
    cat > "$package_dir/package-info.md" << EOF
# $(jq -r '.meta.name' "$THEME_CONFIG") Theme Package

**Author:** $(jq -r '.meta.author // "Unknown"' "$THEME_CONFIG")
**Version:** $(jq -r '.meta.version // "1.0"' "$THEME_CONFIG")
**Exported:** $(date)
**Description:** $(jq -r '.meta.description // "No description"' "$THEME_CONFIG")

## Installation

1. Extract this package to a temporary directory
2. Import using the Cyberpunk Medieval theme import manager:
   \`~/.config/hypr-system/scripts/theme-import.sh\`
3. Or copy \`theme-config.json\` to your themes directory manually

## Contents

- \`theme-config.json\` - Main theme configuration
- \`wallpapers/\` - Theme wallpapers (if any)
- \`scripts/\` - Custom scripts (if any)
- \`package-info.md\` - This file

## Compatibility

This theme is designed for the Cyberpunk Medieval Hyprland setup.
Ensure you have the base system installed before importing.
EOF

    # Create installation script
    cat > "$package_dir/install.sh" << 'EOF'
#!/bin/bash
# Theme package installer

HYPR_SYSTEM_DIR="$HOME/.config/hypr-system"

if [[ ! -d "$HYPR_SYSTEM_DIR" ]]; then
    echo "❌ Cyberpunk Medieval Hyprland setup not found"
    echo "Please install the base system first"
    exit 1
fi

echo "📥 Installing theme package..."

# Copy theme config
if [[ -f "theme-config.json" ]]; then
    cp "theme-config.json" "$HYPR_SYSTEM_DIR/core/"
    echo "✅ Theme configuration installed"
fi

# Copy wallpapers
if [[ -d "wallpapers" ]]; then
    local theme_name=$(jq -r '.meta.name // "imported-theme"' "theme-config.json" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    mkdir -p "$HYPR_SYSTEM_DIR/wallpapers/$theme_name"
    cp -r wallpapers/* "$HYPR_SYSTEM_DIR/wallpapers/$theme_name/"
    echo "✅ Wallpapers installed"
fi

# Copy scripts
if [[ -d "scripts" ]]; then
    mkdir -p "$HYPR_SYSTEM_DIR/custom-scripts"
    cp -r scripts/* "$HYPR_SYSTEM_DIR/custom-scripts/"
    chmod +x "$HYPR_SYSTEM_DIR/custom-scripts"/*.sh 2>/dev/null
    echo "✅ Custom scripts installed"
fi

echo "🎨 Theme package installed successfully!"
echo "Run the theme manager to apply: ~/.config/hypr-system/scripts/theme-manager.sh"
EOF

    chmod +x "$package_dir/install.sh"

    # Create the package
    cd "$temp_dir"
    tar -czf "$export_file" "$export_name"

    # Cleanup
    rm -rf "$temp_dir"

    notify-send "📦 Package Exported" "Complete theme package: $(basename "$export_file")" -t 3000
    echo "$export_file"
}

# Function to export for sharing (minimal)
export_for_sharing() {
    local export_name="$1"
    local export_file="$EXPORT_DIR/${export_name}-share.json"

    if [[ ! -f "$THEME_CONFIG" ]]; then
        notify-send "❌ No Theme Config" "Theme configuration not found" -t 3000
        return 1
    fi

    # Create a minimal sharing version with only essential data
    jq '{
        meta: .meta,
        colors: .colors,
        typography: .typography,
        spacing: .spacing,
        effects: .effects
    }' "$THEME_CONFIG" > "$export_file"

    # Add sharing metadata
    local temp_file=$(mktemp)
    jq --arg shared "$(date)" --arg url "https://github.com/sssolid/oxidized" \
       '.meta.shared_date = $shared | .meta.source_url = $url | .meta.sharing_version = true' \
       "$export_file" > "$temp_file"

    mv "$temp_file" "$export_file"

    notify-send "🌐 Share Export" "Minimal theme for sharing: $(basename "$export_file")" -t 3000
    echo "$export_file"
}

# Function to export to GitHub Gist
export_to_gist() {
    local export_name="$1"

    if ! command -v curl >/dev/null 2>&1; then
        notify-send "❌ Missing curl" "curl required for Gist upload" -t 3000
        return 1
    fi

    # Create JSON for sharing
    local temp_file=$(mktemp)
    export_for_sharing "$export_name" > /dev/null
    local share_file="$EXPORT_DIR/${export_name}-share.json"

    # Get GitHub token (if configured)
    local github_token=""
    if [[ -f "$HOME/.config/github-token" ]]; then
        github_token=$(cat "$HOME/.config/github-token")
    fi

    # Prepare Gist data
    local gist_data=$(jq -n \
        --arg filename "${export_name}.json" \
        --arg content "$(cat "$share_file")" \
        --arg description "$(jq -r '.meta.name' "$THEME_CONFIG") - Cyberpunk Medieval Hyprland Theme" \
        '{
            description: $description,
            public: true,
            files: {
                ($filename): {
                    content: $content
                }
            }
        }')

    # Upload to Gist
    local auth_header=""
    if [[ -n "$github_token" ]]; then
        auth_header="-H \"Authorization: token $github_token\""
    fi

    local response=$(curl -s $auth_header \
        -X POST \
        -H "Accept: application/vnd.github.v3+json" \
        -d "$gist_data" \
        https://api.github.com/gists)

    local gist_url=$(echo "$response" | jq -r '.html_url // empty')

    if [[ -n "$gist_url" ]]; then
        echo "$gist_url" | wl-copy 2>/dev/null || echo "$gist_url" | xclip -selection clipboard 2>/dev/null
        notify-send "🌐 Gist Created" "Theme uploaded to: $gist_url\nURL copied to clipboard" -t 5000
        echo "$gist_url"
    else
        notify-send "❌ Gist Failed" "Failed to upload to GitHub Gist" -t 3000
        return 1
    fi

    rm -f "$temp_file" "$share_file"
}

# Function to export wallpapers only
export_wallpapers() {
    local export_name="$1"
    local current_theme_id=""

    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        current_theme_id=$(cat "$SCRIPT_DIR/.current-theme")
    else
        notify-send "❌ No Current Theme" "No active theme found" -t 3000
        return 1
    fi

    local wallpaper_source="$SCRIPT_DIR/wallpapers/$current_theme_id"
    if [[ ! -d "$wallpaper_source" ]] || [[ -z "$(ls -A "$wallpaper_source" 2>/dev/null)" ]]; then
        notify-send "❌ No Wallpapers" "No wallpapers found for current theme" -t 3000
        return 1
    fi

    local export_file="$EXPORT_DIR/${export_name}-wallpapers.tar.gz"

    cd "$wallpaper_source"
    tar -czf "$export_file" *

    local wallpaper_count=$(find "$wallpaper_source" -type f | wc -l)
    notify-send "🖼️ Wallpapers Exported" "Exported $wallpaper_count wallpapers to: $(basename "$export_file")" -t 3000

    echo "$export_file"
}

# Function to show export options
show_export_options() {
    if [[ ! -f "$THEME_CONFIG" ]]; then
        notify-send "❌ No Theme" "No theme configuration found to export" -t 3000
        return 1
    fi

    local theme_info=$(get_current_theme_info)
    IFS='|' read -r theme_name theme_author theme_version <<< "$theme_info"

    local export_options=(
        "📄 Export as JSON|Export theme configuration only|json"
        "📦 Export Complete Package|Export theme with wallpapers and assets|package"
        "🌐 Export for Sharing|Export minimal theme for easy sharing|share"
        "🖼️ Export Wallpapers Only|Export just the wallpapers|wallpapers"
        "📤 Upload to GitHub Gist|Share theme via GitHub Gist|gist"
        "📋 Copy to Clipboard|Copy theme JSON to clipboard|clipboard"
        "👁️ Preview Export|Show what will be exported|preview"
    )

    local menu_items=()
    local actions=()

    for option in "${export_options[@]}"; do
        IFS='|' read -r display description action <<< "$option"
        menu_items+=("$display")
        actions+=("$action")
    done

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "📤 Export '$theme_name'" \
        -theme "$ROFI_THEME" \
        -markup-rows \
        -width 50)

    if [[ -z "$selected" ]]; then
        return 0
    fi

    # Find the selected action
    for i in "${!menu_items[@]}"; do
        if [[ "${menu_items[$i]}" == "$selected" ]]; then
            local action="${actions[$i]}"
            execute_export_action "$action" "$theme_name"
            break
        fi
    done
}

# Function to execute export action
execute_export_action() {
    local action="$1"
    local theme_name="$2"

    # Sanitize theme name for filename
    local safe_name=$(echo "$theme_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local export_name="${safe_name}-${timestamp}"

    case "$action" in
        "json")
            local exported_file=$(export_as_json "$export_name")
            show_export_result "$exported_file"
            ;;
        "package")
            local exported_file=$(export_as_package "$export_name")
            show_export_result "$exported_file"
            ;;
        "share")
            local exported_file=$(export_for_sharing "$export_name")
            show_export_result "$exported_file"
            ;;
        "wallpapers")
            local exported_file=$(export_wallpapers "$export_name")
            show_export_result "$exported_file"
            ;;
        "gist")
            export_to_gist "$export_name"
            ;;
        "clipboard")
            copy_to_clipboard
            ;;
        "preview")
            show_export_preview
            ;;
    esac
}

# Function to copy theme to clipboard
copy_to_clipboard() {
    if [[ ! -f "$THEME_CONFIG" ]]; then
        notify-send "❌ No Theme" "No theme configuration found" -t 3000
        return 1
    fi

    # Copy formatted JSON to clipboard
    jq . "$THEME_CONFIG" | wl-copy 2>/dev/null || jq . "$THEME_CONFIG" | xclip -selection clipboard 2>/dev/null

    if [[ $? -eq 0 ]]; then
        notify-send "📋 Copied to Clipboard" "Theme configuration copied to clipboard" -t 3000
    else
        notify-send "❌ Copy Failed" "Could not copy to clipboard" -t 3000
    fi
}

# Function to show export preview
show_export_preview() {
    if [[ ! -f "$THEME_CONFIG" ]]; then
        notify-send "❌ No Theme" "No theme configuration found" -t 3000
        return 1
    fi

    local theme_name=$(jq -r '.meta.name // "Unknown"' "$THEME_CONFIG")
    local theme_author=$(jq -r '.meta.author // "Unknown"' "$THEME_CONFIG")
    local theme_version=$(jq -r '.meta.version // "1.0"' "$THEME_CONFIG")
    local theme_description=$(jq -r '.meta.description // "No description"' "$THEME_CONFIG")

    local primary_bg=$(jq -r '.colors.primary.bg_primary // "#000000"' "$THEME_CONFIG")
    local accent_color=$(jq -r '.colors.cyberpunk.neon_cyan // "#00ffff"' "$THEME_CONFIG")
    local font_family=$(jq -r '.typography.font_primary // "Unknown"' "$THEME_CONFIG")

    # Count wallpapers
    local wallpaper_count=0
    local current_theme_id=""
    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        current_theme_id=$(cat "$SCRIPT_DIR/.current-theme")
        if [[ -d "$SCRIPT_DIR/wallpapers/$current_theme_id" ]]; then
            wallpaper_count=$(find "$SCRIPT_DIR/wallpapers/$current_theme_id" -type f | wc -l)
        fi
    fi

    local config_size=$(du -h "$THEME_CONFIG" | cut -f1)

    local preview_info="📤 EXPORT PREVIEW

Theme Information:
  Name: $theme_name
  Author: $theme_author
  Version: $theme_version
  Description: $theme_description

Visual Properties:
  Primary Background: $primary_bg
  Accent Color: $accent_color
  Font Family: $font_family

Export Contents:
  Configuration: $config_size
  Wallpapers: $wallpaper_count files
  Custom Scripts: $(find "$SCRIPT_DIR/custom-scripts" -name "*.sh" 2>/dev/null | wc -l) files

Export Options:
  📄 JSON: Configuration only (~$config_size)
  📦 Package: Complete theme with assets
  🌐 Share: Minimal version for sharing
  🖼️ Wallpapers: Images only"

    echo "$preview_info" | rofi -dmenu -p "👁️ Export Preview" \
        -theme "$ROFI_THEME" -no-custom -width 60
}

# Function to show export result
show_export_result() {
    local exported_file="$1"

    if [[ -z "$exported_file" || ! -f "$exported_file" ]]; then
        return 1
    fi

    local file_size=$(du -h "$exported_file" | cut -f1)
    local file_name=$(basename "$exported_file")

    local result_options=(
        "📁 Open Export Directory"
        "📋 Copy File Path"
        "📤 Share via Email"
        "🔗 Generate Share Link"
        "✅ Done"
    )

    local selected=$(printf '%s\n' "${result_options[@]}" | \
        rofi -dmenu -p "✅ Exported: $file_name ($file_size)" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📁 Open Export Directory")
            thunar "$EXPORT_DIR" &
            ;;
        "📋 Copy File Path")
            echo "$exported_file" | wl-copy 2>/dev/null || echo "$exported_file" | xclip -selection clipboard 2>/dev/null
            notify-send "📋 Path Copied" "File path copied to clipboard" -t 2000
            ;;
        "📤 Share via Email")
            if command -v thunderbird >/dev/null 2>&1; then
                thunderbird -compose "subject=Cyberpunk Medieval Theme,attachment='$exported_file'" &
            elif command -v evolution >/dev/null 2>&1; then
                evolution "mailto:?subject=Cyberpunk Medieval Theme&attach=$exported_file" &
            else
                notify-send "📧 Email Client" "No email client found. File ready at: $exported_file" -t 5000
            fi
            ;;
        "🔗 Generate Share Link")
            notify-send "🔗 Share Link" "Upload to cloud storage or file sharing service manually" -t 3000
            ;;
    esac
}

# Main export manager
main() {
    if ! check_dependencies; then
        exit 1
    fi

    # Ensure export directory exists
    mkdir -p "$EXPORT_DIR"

    case "${1:-menu}" in
        "menu")
            show_export_options
            ;;
        "json")
            local theme_info=$(get_current_theme_info)
            IFS='|' read -r theme_name _ _ <<< "$theme_info"
            local safe_name=$(echo "$theme_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
            export_as_json "$safe_name-$(date +%Y%m%d_%H%M%S)"
            ;;
        "package")
            local theme_info=$(get_current_theme_info)
            IFS='|' read -r theme_name _ _ <<< "$theme_info"
            local safe_name=$(echo "$theme_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
            export_as_package "$safe_name-$(date +%Y%m%d_%H%M%S)"
            ;;
        "share")
            local theme_info=$(get_current_theme_info)
            IFS='|' read -r theme_name _ _ <<< "$theme_info"
            local safe_name=$(echo "$theme_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
            export_for_sharing "$safe_name-$(date +%Y%m%d_%H%M%S)"
            ;;
        "clipboard")
            copy_to_clipboard
            ;;
        "gist")
            local theme_info=$(get_current_theme_info)
            IFS='|' read -r theme_name _ _ <<< "$theme_info"
            local safe_name=$(echo "$theme_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
            export_to_gist "$safe_name"
            ;;
        *)
            echo "📤 Theme Export Manager"
            echo ""
            echo "Usage: $0 {menu|json|package|share|clipboard|gist}"
            echo ""
            echo "Commands:"
            echo "  menu       - Show export options menu"
            echo "  json       - Export as JSON file"
            echo "  package    - Export complete package"
            echo "  share      - Export for sharing"
            echo "  clipboard  - Copy to clipboard"
            echo "  gist       - Upload to GitHub Gist"
            ;;
    esac
}

# Run main function
main "$@"
