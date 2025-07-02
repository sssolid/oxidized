#!/bin/bash
# ⚙️ Dynamic Configuration Menu
# Central hub for all configuration management

CONFIG_DIR="$HOME/.config/hypr-system"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Check if required directories exist
if [[ ! -d "$CONFIG_DIR" ]]; then
    notify-send "❌ Error" "Hypr-system not found. Please install first." -t 5000
    exit 1
fi

# Menu options with icons and descriptions
declare -A menu_options=(
    ["🎨 Theme Editor"]="$CONFIG_DIR/scripts/theme-editor.sh|Edit colors, fonts, and visual settings"
    ["⌨️ Keybinding Editor"]="$CONFIG_DIR/scripts/keybind-editor.sh|Modify hotkeys and shortcuts"
    ["🖼️ Wallpaper Manager"]="$CONFIG_DIR/scripts/wallpaper-manager.sh|Change wallpapers and backgrounds"
    ["📊 Waybar Config"]="$CONFIG_DIR/scripts/waybar-editor.sh|Customize status bar modules"
    ["🔧 System Settings"]="$CONFIG_DIR/scripts/system-editor.sh|Adjust system-wide preferences"
    ["📱 Component Config"]="$CONFIG_DIR/scripts/component-editor.sh|Configure individual components"
    ["🗡️ Show Hotkeys"]="$CONFIG_DIR/scripts/hotkey-display.sh|Display all keyboard shortcuts"
    ["🔄 Apply Changes"]="$CONFIG_DIR/generators/apply-theme.py|Regenerate all configurations"
    ["📄 Edit Theme JSON"]="code '$CONFIG_DIR/core/theme-config.json'|Direct edit theme configuration"
    ["⌨️ Edit Keybind JSON"]="code '$CONFIG_DIR/core/keybind-config.json'|Direct edit keybinding configuration"
    ["📁 Open Config Folder"]="thunar '$CONFIG_DIR'|Browse configuration directory"
    ["🔧 Reload Hyprland"]="hyprctl reload|Restart Hyprland compositor"
    ["📊 Restart Waybar"]="pkill waybar && waybar &|Restart status bar"
    ["🔔 Restart Dunst"]="pkill dunst && dunst &|Restart notification daemon"
    ["💾 Backup Config"]="$CONFIG_DIR/scripts/backup-config.sh|Create configuration backup"
    ["📥 Import Theme"]="$CONFIG_DIR/scripts/import-theme.sh|Import external theme"
    ["📤 Export Theme"]="$CONFIG_DIR/scripts/export-theme.sh|Export current theme"
)

# Create menu items array
menu_items=()
commands=()
descriptions=()

for item in "${!menu_options[@]}"; do
    IFS='|' read -r command description <<< "${menu_options[$item]}"
    menu_items+=("$item")
    commands+=("$command")
    descriptions+=("$description")
done

# Sort menu items for better organization
IFS=$'\n' sorted_items=($(sort <<<"${menu_items[*]}"))
unset IFS

# Create rofi menu format
rofi_input=""
for item in "${sorted_items[@]}"; do
    # Find the description for this item
    for i in "${!menu_items[@]}"; do
        if [[ "${menu_items[$i]}" == "$item" ]]; then
            rofi_input+="$item\n"
            break
        fi
    done
done

# Show menu with rofi
selected=$(echo -e "$rofi_input" | rofi -dmenu \
    -p "⚙️ Configuration" \
    -theme "$ROFI_THEME" \
    -markup-rows \
    -width 50 \
    -lines 15 \
    -font "JetBrains Mono Nerd Font 13" \
    -no-custom)

# Execute selected command
if [[ -n "$selected" ]]; then
    # Find the command for the selected item
    for i in "${!menu_items[@]}"; do
        if [[ "${menu_items[$i]}" == "$selected" ]]; then
            command="${commands[$i]}"
            description="${descriptions[$i]}"

            # Show notification
            notify-send "⚙️ Config" "Opening: $description" -t 2000

            # Execute command
            if [[ "$command" == *"code "* ]]; then
                # Handle VS Code commands specially
                eval "$command" &
            elif [[ "$command" == *".py" ]]; then
                # Python scripts
                cd "$CONFIG_DIR" && python3 "$command" &
            elif [[ "$command" == *".sh" ]]; then
                # Shell scripts
                bash "$command" &
            elif [[ "$command" == *"thunar"* ]]; then
                # File manager
                eval "$command" &
            elif [[ "$command" == *"hyprctl"* ]] || [[ "$command" == *"pkill"* ]]; then
                # System commands
                bash -c "$command"
                notify-send "✅ Done" "Command executed successfully" -t 2000
            else
                # Generic command
                bash -c "$command" &
            fi
            break
        fi
    done
fi
