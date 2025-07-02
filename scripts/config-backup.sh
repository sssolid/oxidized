#!/bin/bash
# 💾 Configuration Backup Manager
# Comprehensive backup and restore system for all configurations

SCRIPT_DIR="$HOME/.config/hypr-system"
BACKUP_DIR="$SCRIPT_DIR/backups"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"
GREEN="#39ff14"
CRIMSON="#dc143c"

# Function to create timestamp
get_timestamp() {
    date +%Y%m%d_%H%M%S
}

# Function to get human-readable date
get_human_date() {
    local timestamp="$1"
    # Convert timestamp to human readable format
    if [[ "$timestamp" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})$ ]]; then
        local year="${BASH_REMATCH[1]}"
        local month="${BASH_REMATCH[2]}"
        local day="${BASH_REMATCH[3]}"
        local hour="${BASH_REMATCH[4]}"
        local minute="${BASH_REMATCH[5]}"
        local second="${BASH_REMATCH[6]}"
        echo "$year-$month-$day $hour:$minute:$second"
    else
        echo "$timestamp"
    fi
}

# Function to create full system backup
create_full_backup() {
    local backup_name="full_backup_$(get_timestamp)"
    local backup_path="$BACKUP_DIR/$backup_name"

    notify-send "💾 Creating Backup" "Starting full system backup..." -t 3000

    mkdir -p "$backup_path"

    # Create backup info file
    cat > "$backup_path/backup_info.json" << EOF
{
  "backup_name": "$backup_name",
  "timestamp": "$(get_timestamp)",
  "date": "$(date)",
  "type": "full_backup",
  "hostname": "$(hostname)",
  "user": "$USER",
  "hyprland_version": "$(hyprctl version | head -1 2>/dev/null || echo "unknown")",
  "backup_size": "",
  "components": []
}
EOF

    local backed_up_components=()

    # Backup Hyprland system configs
    if [[ -d "$SCRIPT_DIR" ]]; then
        cp -r "$SCRIPT_DIR"/* "$backup_path/hypr-system/" 2>/dev/null
        backed_up_components+=("hypr-system")
    fi

    # Backup Hyprland configs
    if [[ -d "$HOME/.config/hypr" ]]; then
        cp -r "$HOME/.config/hypr" "$backup_path/" 2>/dev/null
        backed_up_components+=("hypr")
    fi

    # Backup Waybar
    if [[ -d "$HOME/.config/waybar" ]]; then
        cp -r "$HOME/.config/waybar" "$backup_path/" 2>/dev/null
        backed_up_components+=("waybar")
    fi

    # Backup Rofi
    if [[ -d "$HOME/.config/rofi" ]]; then
        cp -r "$HOME/.config/rofi" "$backup_path/" 2>/dev/null
        backed_up_components+=("rofi")
    fi

    # Backup Dunst
    if [[ -d "$HOME/.config/dunst" ]]; then
        cp -r "$HOME/.config/dunst" "$backup_path/" 2>/dev/null
        backed_up_components+=("dunst")
    fi

    # Backup Kitty
    if [[ -d "$HOME/.config/kitty" ]]; then
        cp -r "$HOME/.config/kitty" "$backup_path/" 2>/dev/null
        backed_up_components+=("kitty")
    fi

    # Backup EWW
    if [[ -d "$HOME/.config/eww" ]]; then
        cp -r "$HOME/.config/eww" "$backup_path/" 2>/dev/null
        backed_up_components+=("eww")
    fi

    # Backup wallpapers
    if [[ -d "$SCRIPT_DIR/wallpapers" ]]; then
        cp -r "$SCRIPT_DIR/wallpapers" "$backup_path/" 2>/dev/null
        backed_up_components+=("wallpapers")
    fi

    # Update backup info with components
    local temp_file=$(mktemp)
    jq --argjson components "$(printf '%s\n' "${backed_up_components[@]}" | jq -R . | jq -s .)" \
       '.components = $components' "$backup_path/backup_info.json" > "$temp_file" && \
    mv "$temp_file" "$backup_path/backup_info.json"

    # Calculate backup size
    local backup_size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
    jq --arg size "$backup_size" '.backup_size = $size' "$backup_path/backup_info.json" > "$temp_file" && \
    mv "$temp_file" "$backup_path/backup_info.json"

    # Compress backup
    if command -v tar >/dev/null 2>&1; then
        cd "$BACKUP_DIR"
        tar -czf "${backup_name}.tar.gz" "$backup_name"
        rm -rf "$backup_name"
        backup_path="${backup_path}.tar.gz"
    fi

    notify-send "✅ Backup Complete" "Full backup created: $backup_name" -t 5000
    echo "$backup_path"
}

# Function to create theme-only backup
create_theme_backup() {
    local backup_name="theme_backup_$(get_timestamp)"
    local backup_path="$BACKUP_DIR/$backup_name"

    notify-send "🎨 Creating Theme Backup" "Backing up theme configuration..." -t 2000

    mkdir -p "$backup_path"

    # Backup theme configs
    cp "$SCRIPT_DIR/core/theme-config.json" "$backup_path/" 2>/dev/null
    cp "$SCRIPT_DIR/core/keybind-config.json" "$backup_path/" 2>/dev/null

    # Backup current theme
    if [[ -f "$SCRIPT_DIR/.current-theme" ]]; then
        cp "$SCRIPT_DIR/.current-theme" "$backup_path/" 2>/dev/null
    fi

    # Create backup info
    cat > "$backup_path/backup_info.json" << EOF
{
  "backup_name": "$backup_name",
  "timestamp": "$(get_timestamp)",
  "date": "$(date)",
  "type": "theme_backup",
  "current_theme": "$(cat "$SCRIPT_DIR/.current-theme" 2>/dev/null || echo "unknown")"
}
EOF

    notify-send "✅ Theme Backup Complete" "Theme backup created: $backup_name" -t 3000
    echo "$backup_path"
}

# Function to create component backup
create_component_backup() {
    local component="$1"
    local backup_name="${component}_backup_$(get_timestamp)"
    local backup_path="$BACKUP_DIR/$backup_name"

    notify-send "📱 Creating Component Backup" "Backing up $component configuration..." -t 2000

    mkdir -p "$backup_path"

    case "$component" in
        "waybar")
            cp -r "$HOME/.config/waybar" "$backup_path/" 2>/dev/null
            ;;
        "rofi")
            cp -r "$HOME/.config/rofi" "$backup_path/" 2>/dev/null
            ;;
        "dunst")
            cp -r "$HOME/.config/dunst" "$backup_path/" 2>/dev/null
            ;;
        "kitty")
            cp -r "$HOME/.config/kitty" "$backup_path/" 2>/dev/null
            ;;
        "eww")
            cp -r "$HOME/.config/eww" "$backup_path/" 2>/dev/null
            ;;
        "hyprland")
            cp -r "$HOME/.config/hypr" "$backup_path/" 2>/dev/null
            ;;
    esac

    # Create backup info
    cat > "$backup_path/backup_info.json" << EOF
{
  "backup_name": "$backup_name",
  "timestamp": "$(get_timestamp)",
  "date": "$(date)",
  "type": "component_backup",
  "component": "$component"
}
EOF

    notify-send "✅ Component Backup Complete" "$component backup created: $backup_name" -t 3000
    echo "$backup_path"
}

# Function to list available backups
list_backups() {
    local backup_type="${1:-all}"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        notify-send "📋 No Backups" "No backup directory found" -t 3000
        return 1
    fi

    local backups=()

    # Find backup directories and archives
    for backup in "$BACKUP_DIR"/*; do
        if [[ -d "$backup" ]] || [[ -f "$backup" && "$backup" =~ \.tar\.gz$ ]]; then
            local backup_name=$(basename "$backup" .tar.gz)

            # Check backup type filter
            case "$backup_type" in
                "theme")
                    [[ "$backup_name" =~ ^theme_backup_ ]] && backups+=("$backup_name")
                    ;;
                "full")
                    [[ "$backup_name" =~ ^full_backup_ ]] && backups+=("$backup_name")
                    ;;
                "component")
                    [[ "$backup_name" =~ _backup_ ]] && [[ ! "$backup_name" =~ ^(theme|full)_backup_ ]] && backups+=("$backup_name")
                    ;;
                *)
                    backups+=("$backup_name")
                    ;;
            esac
        fi
    done

    if [[ ${#backups[@]} -eq 0 ]]; then
        notify-send "📋 No Backups" "No backups found for type: $backup_type" -t 3000
        return 1
    fi

    # Sort backups by timestamp (newest first)
    IFS=$'\n' sorted_backups=($(sort -r <<<"${backups[*]}"))
    unset IFS

    printf '%s\n' "${sorted_backups[@]}"
}

# Function to show backup details
show_backup_details() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/$backup_name"
    local info_file=""

    # Check if it's a compressed backup
    if [[ -f "$backup_path.tar.gz" ]]; then
        # Extract backup info from compressed file
        local temp_dir=$(mktemp -d)
        tar -xzf "$backup_path.tar.gz" -C "$temp_dir" "$backup_name/backup_info.json" 2>/dev/null
        info_file="$temp_dir/$backup_name/backup_info.json"
    elif [[ -f "$backup_path/backup_info.json" ]]; then
        info_file="$backup_path/backup_info.json"
    fi

    if [[ -f "$info_file" ]]; then
        local backup_info=$(jq -r '
            "Backup Name: " + .backup_name + "\n" +
            "Date: " + .date + "\n" +
            "Type: " + .type + "\n" +
            (if .current_theme then "Theme: " + .current_theme + "\n" else "" end) +
            (if .component then "Component: " + .component + "\n" else "" end) +
            (if .backup_size then "Size: " + .backup_size + "\n" else "" end) +
            (if .components then "Components: " + (.components | join(", ")) else "" end)
        ' "$info_file")

        echo "$backup_info" | rofi -dmenu -p "📋 Backup Details" \
            -theme "$ROFI_THEME" -no-custom -width 60
    else
        local simple_info="Backup: $backup_name
Date: $(get_human_date "${backup_name##*_}")
Type: Legacy Backup"

        echo "$simple_info" | rofi -dmenu -p "📋 Backup Details" \
            -theme "$ROFI_THEME" -no-custom
    fi

    # Cleanup temp directory if created
    [[ -n "${temp_dir:-}" ]] && rm -rf "$temp_dir"
}

# Function to restore backup
restore_backup() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/$backup_name"

    # Check if backup exists
    if [[ ! -d "$backup_path" && ! -f "$backup_path.tar.gz" ]]; then
        notify-send "❌ Backup Not Found" "Backup $backup_name does not exist" -t 3000
        return 1
    fi

    # Confirm restoration
    if ! rofi -dmenu -p "⚠️ Restore backup $backup_name? This will overwrite current configs!" <<< $'Yes\nNo' | grep -q "Yes"; then
        return 0
    fi

    notify-send "🔄 Restoring Backup" "Restoring $backup_name..." -t 3000

    # Create backup of current state first
    local current_backup=$(create_full_backup)
    notify-send "💾 Current State Backed Up" "Created backup before restore" -t 2000

    # Extract compressed backup if needed
    local source_path="$backup_path"
    if [[ -f "$backup_path.tar.gz" ]]; then
        local temp_dir=$(mktemp -d)
        tar -xzf "$backup_path.tar.gz" -C "$temp_dir"
        source_path="$temp_dir/$backup_name"
    fi

    # Restore configurations
    local restored_components=()

    # Restore hypr-system
    if [[ -d "$source_path/hypr-system" ]]; then
        cp -r "$source_path/hypr-system"/* "$SCRIPT_DIR/" 2>/dev/null
        restored_components+=("hypr-system")
    fi

    # Restore Hyprland
    if [[ -d "$source_path/hypr" ]]; then
        rm -rf "$HOME/.config/hypr"
        cp -r "$source_path/hypr" "$HOME/.config/" 2>/dev/null
        restored_components+=("hypr")
    fi

    # Restore Waybar
    if [[ -d "$source_path/waybar" ]]; then
        rm -rf "$HOME/.config/waybar"
        cp -r "$source_path/waybar" "$HOME/.config/" 2>/dev/null
        restored_components+=("waybar")
    fi

    # Restore Rofi
    if [[ -d "$source_path/rofi" ]]; then
        rm -rf "$HOME/.config/rofi"
        cp -r "$source_path/rofi" "$HOME/.config/" 2>/dev/null
        restored_components+=("rofi")
    fi

    # Restore Dunst
    if [[ -d "$source_path/dunst" ]]; then
        rm -rf "$HOME/.config/dunst"
        cp -r "$source_path/dunst" "$HOME/.config/" 2>/dev/null
        restored_components+=("dunst")
    fi

    # Restore Kitty
    if [[ -d "$source_path/kitty" ]]; then
        rm -rf "$HOME/.config/kitty"
        cp -r "$source_path/kitty" "$HOME/.config/" 2>/dev/null
        restored_components+=("kitty")
    fi

    # Restore EWW
    if [[ -d "$source_path/eww" ]]; then
        rm -rf "$HOME/.config/eww"
        cp -r "$source_path/eww" "$HOME/.config/" 2>/dev/null
        restored_components+=("eww")
    fi

    # Restore wallpapers
    if [[ -d "$source_path/wallpapers" ]]; then
        rm -rf "$SCRIPT_DIR/wallpapers"
        cp -r "$source_path/wallpapers" "$SCRIPT_DIR/" 2>/dev/null
        restored_components+=("wallpapers")
    fi

    # Cleanup temp directory if created
    [[ -n "${temp_dir:-}" ]] && rm -rf "$temp_dir"

    # Restart services
    notify-send "🔄 Restarting Services" "Reloading configuration..." -t 2000

    hyprctl reload 2>/dev/null
    pkill waybar && waybar &
    pkill dunst && dunst &

    notify-send "✅ Restore Complete" "Restored: ${restored_components[*]}" -t 5000
}

# Function to delete backup
delete_backup() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/$backup_name"

    if ! rofi -dmenu -p "🗑️ Delete backup $backup_name?" <<< $'Yes\nNo' | grep -q "Yes"; then
        return 0
    fi

    # Remove backup directory or archive
    if [[ -d "$backup_path" ]]; then
        rm -rf "$backup_path"
    elif [[ -f "$backup_path.tar.gz" ]]; then
        rm -f "$backup_path.tar.gz"
    else
        notify-send "❌ Backup Not Found" "Backup $backup_name does not exist" -t 3000
        return 1
    fi

    notify-send "🗑️ Backup Deleted" "Deleted backup: $backup_name" -t 3000
}

# Function to export backup
export_backup() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/$backup_name"
    local export_path="$HOME/Desktop/${backup_name}.tar.gz"

    # Check if backup exists
    if [[ -f "$backup_path.tar.gz" ]]; then
        cp "$backup_path.tar.gz" "$export_path"
    elif [[ -d "$backup_path" ]]; then
        cd "$BACKUP_DIR"
        tar -czf "$export_path" "$backup_name"
    else
        notify-send "❌ Backup Not Found" "Backup $backup_name does not exist" -t 3000
        return 1
    fi

    notify-send "📤 Backup Exported" "Exported to: $export_path" -t 3000
}

# Function to import backup
import_backup() {
    local import_file=$(echo "" | rofi -dmenu -p "Enter path to backup file (.tar.gz):")

    if [[ -z "$import_file" || ! -f "$import_file" ]]; then
        notify-send "❌ File Not Found" "Backup file not found or invalid" -t 3000
        return 1
    fi

    # Extract to backup directory
    local import_name="imported_backup_$(get_timestamp)"

    cd "$BACKUP_DIR"
    if tar -xzf "$import_file"; then
        # Find the extracted directory
        local extracted_dir=$(tar -tzf "$import_file" | head -1 | cut -f1 -d'/')

        # Rename to standard format
        if [[ -d "$extracted_dir" ]]; then
            mv "$extracted_dir" "$import_name"
        fi

        notify-send "📥 Backup Imported" "Imported as: $import_name" -t 3000
    else
        notify-send "❌ Import Failed" "Could not extract backup file" -t 3000
    fi
}

# Function to manage backup storage
manage_backup_storage() {
    local storage_menu=(
        "📊 Storage Information"
        "🧹 Clean Old Backups"
        "📦 Compress Backups"
        "📁 Open Backup Directory"
        "⚙️ Backup Settings"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${storage_menu[@]}" | \
        rofi -dmenu -p "💾 Backup Storage" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📊 Storage Information")
            show_storage_info
            ;;
        "🧹 Clean Old Backups")
            clean_old_backups
            ;;
        "📦 Compress Backups")
            compress_backups
            ;;
        "📁 Open Backup Directory")
            thunar "$BACKUP_DIR" &
            ;;
        "⚙️ Backup Settings")
            configure_backup_settings
            ;;
    esac
}

# Function to show storage info
show_storage_info() {
    local total_backups=$(find "$BACKUP_DIR" -maxdepth 1 \( -type d -o -name "*.tar.gz" \) | wc -l)
    local backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    local available_space=$(df -h "$BACKUP_DIR" | awk 'NR==2 {print $4}')

    local storage_info="💾 BACKUP STORAGE INFORMATION

Total Backups: $total_backups
Backup Directory Size: $backup_size
Available Space: $available_space
Location: $BACKUP_DIR

Backup Types:
Full Backups: $(ls "$BACKUP_DIR"/full_backup_* 2>/dev/null | wc -l)
Theme Backups: $(ls "$BACKUP_DIR"/theme_backup_* 2>/dev/null | wc -l)
Component Backups: $(ls "$BACKUP_DIR"/*_backup_* 2>/dev/null | grep -v "full_backup\|theme_backup" | wc -l)"

    echo "$storage_info" | rofi -dmenu -p "📊 Storage Info" \
        -theme "$ROFI_THEME" -no-custom -width 60
}

# Function to clean old backups
clean_old_backups() {
    local cleanup_options=(
        "🗑️ Remove backups older than 30 days"
        "🗑️ Remove backups older than 7 days"
        "🗑️ Keep only last 10 backups"
        "🗑️ Keep only last 5 backups"
        "🔙 Cancel"
    )

    local selected=$(printf '%s\n' "${cleanup_options[@]}" | \
        rofi -dmenu -p "🧹 Cleanup Options" \
        -theme "$ROFI_THEME")

    case "$selected" in
        *"30 days")
            find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +30 -delete
            find "$BACKUP_DIR" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null
            notify-send "🧹 Cleanup Complete" "Removed backups older than 30 days" -t 3000
            ;;
        *"7 days")
            find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -delete
            find "$BACKUP_DIR" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null
            notify-send "🧹 Cleanup Complete" "Removed backups older than 7 days" -t 3000
            ;;
        *"last 10")
            # Keep only the 10 most recent backups
            ls -t "$BACKUP_DIR"/ | tail -n +11 | while read -r backup; do
                rm -rf "$BACKUP_DIR/$backup"
            done
            notify-send "🧹 Cleanup Complete" "Kept only the 10 most recent backups" -t 3000
            ;;
    esac
}

# Main backup manager menu
show_backup_manager() {
    mkdir -p "$BACKUP_DIR"

    local main_menu=(
        "💾 Create Full Backup"
        "🎨 Create Theme Backup"
        "📱 Create Component Backup"
        "📋 List All Backups"
        "🔄 Restore Backup"
        "📤 Export Backup"
        "📥 Import Backup"
        "🗑️ Delete Backup"
        "💾 Backup Storage Management"
        "💾 Save & Exit"
    )

    local selected=$(printf '%s\n' "${main_menu[@]}" | \
        rofi -dmenu -p "💾 Backup Manager" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "💾 Create Full Backup")
            create_full_backup >/dev/null
            ;;
        "🎨 Create Theme Backup")
            create_theme_backup >/dev/null
            ;;
        "📱 Create Component Backup")
            create_component_backup_dialog
            ;;
        "📋 List All Backups")
            list_backups_dialog
            ;;
        "🔄 Restore Backup")
            restore_backup_dialog
            ;;
        "📤 Export Backup")
            export_backup_dialog
            ;;
        "📥 Import Backup")
            import_backup
            ;;
        "🗑️ Delete Backup")
            delete_backup_dialog
            ;;
        "💾 Backup Storage Management")
            manage_backup_storage
            ;;
        "💾 Save & Exit")
            return 0
            ;;
        *)
            return 0
            ;;
    esac

    # Return to main menu unless exiting
    show_backup_manager
}

# Dialog functions
create_component_backup_dialog() {
    local components=("waybar" "rofi" "dunst" "kitty" "eww" "hyprland")
    local selected_component=$(printf '%s\n' "${components[@]}" | \
        rofi -dmenu -p "📱 Select Component to Backup:" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected_component" ]]; then
        create_component_backup "$selected_component" >/dev/null
    fi
}

list_backups_dialog() {
    local backup_types=("all" "full" "theme" "component")
    local selected_type=$(printf '%s\n' "${backup_types[@]}" | \
        rofi -dmenu -p "📋 Select Backup Type:" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected_type" ]]; then
        local backups=($(list_backups "$selected_type"))
        if [[ ${#backups[@]} -gt 0 ]]; then
            local selected_backup=$(printf '%s\n' "${backups[@]}" | \
                rofi -dmenu -p "📋 Available Backups:" \
                -theme "$ROFI_THEME")

            if [[ -n "$selected_backup" ]]; then
                show_backup_details "$selected_backup"
            fi
        fi
    fi
}

restore_backup_dialog() {
    local backups=($(list_backups))
    if [[ ${#backups[@]} -eq 0 ]]; then
        notify-send "📋 No Backups" "No backups available to restore" -t 3000
        return
    fi

    local selected_backup=$(printf '%s\n' "${backups[@]}" | \
        rofi -dmenu -p "🔄 Select Backup to Restore:" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected_backup" ]]; then
        restore_backup "$selected_backup"
    fi
}

export_backup_dialog() {
    local backups=($(list_backups))
    if [[ ${#backups[@]} -eq 0 ]]; then
        notify-send "📋 No Backups" "No backups available to export" -t 3000
        return
    fi

    local selected_backup=$(printf '%s\n' "${backups[@]}" | \
        rofi -dmenu -p "📤 Select Backup to Export:" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected_backup" ]]; then
        export_backup "$selected_backup"
    fi
}

delete_backup_dialog() {
    local backups=($(list_backups))
    if [[ ${#backups[@]} -eq 0 ]]; then
        notify-send "📋 No Backups" "No backups available to delete" -t 3000
        return
    fi

    local selected_backup=$(printf '%s\n' "${backups[@]}" | \
        rofi -dmenu -p "🗑️ Select Backup to Delete:" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected_backup" ]]; then
        delete_backup "$selected_backup"
    fi
}

# Main function
main() {
    case "${1:-menu}" in
        "menu")
            show_backup_manager
            ;;
        "create")
            case "$2" in
                "full") create_full_backup ;;
                "theme") create_theme_backup ;;
                *) create_component_backup "$2" ;;
            esac
            ;;
        "list")
            list_backups "$2"
            ;;
        "restore")
            restore_backup "$2"
            ;;
        "delete")
            delete_backup "$2"
            ;;
        "export")
            export_backup "$2"
            ;;
        "import")
            import_backup
            ;;
        *)
            echo "💾 Configuration Backup Manager"
            echo ""
            echo "Usage: $0 {menu|create|list|restore|delete|export|import}"
            echo ""
            echo "Commands:"
            echo "  menu                    - Show backup manager interface"
            echo "  create {full|theme|component} - Create backup"
            echo "  list [type]            - List available backups"
            echo "  restore <backup_name>  - Restore specific backup"
            echo "  delete <backup_name>   - Delete specific backup"
            echo "  export <backup_name>   - Export backup to desktop"
            echo "  import                 - Import backup from file"
            ;;
    esac
}

# Run main function
main "$@"
