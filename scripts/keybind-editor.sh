#!/bin/bash
# ⌨️ Keybinding Editor
# Visual interface for managing keyboard shortcuts and hotkeys

SCRIPT_DIR="$HOME/.config/hypr-system"
KEYBIND_CONFIG="$SCRIPT_DIR/core/keybind-config.json"
ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
GOLD="#ffd700"
PURPLE="#8a2be2"

# Function to check dependencies
check_dependencies() {
    if ! command -v jq >/dev/null 2>&1; then
        notify-send "❌ Missing Dependency" "jq is required for keybind editing" -t 5000 -u critical
        return 1
    fi

    if [[ ! -f "$KEYBIND_CONFIG" ]]; then
        notify-send "❌ Keybind Config Missing" "Keybinding configuration file not found" -t 5000 -u critical
        return 1
    fi

    return 0
}

# Function to get all categories
get_categories() {
    jq -r '.categories | keys[]' "$KEYBIND_CONFIG" 2>/dev/null
}

# Function to get bindings in a category
get_category_bindings() {
    local category="$1"
    jq -r ".categories.$category.bindings | keys[]" "$KEYBIND_CONFIG" 2>/dev/null
}

# Function to get binding info
get_binding_info() {
    local category="$1"
    local key="$2"
    local field="$3"

    jq -r ".categories.$category.bindings[\"$key\"].$field // empty" "$KEYBIND_CONFIG" 2>/dev/null
}

# Function to set binding info
set_binding_info() {
    local category="$1"
    local key="$2"
    local field="$3"
    local value="$4"
    local temp_file=$(mktemp)

    if jq ".categories.$category.bindings[\"$key\"].$field = \"$value\"" "$KEYBIND_CONFIG" > "$temp_file"; then
        mv "$temp_file" "$KEYBIND_CONFIG"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Function to add new binding
add_new_binding() {
    local category="$1"
    local key="$2"
    local command="$3"
    local description="$4"
    local bind_type="${5:-bind}"
    local temp_file=$(mktemp)

    local binding_json=$(jq -n \
        --arg cmd "$command" \
        --arg desc "$description" \
        --arg type "$bind_type" \
        '{command: $cmd, description: $desc, type: $type}')

    if jq ".categories.$category.bindings[\"$key\"] = $binding_json" "$KEYBIND_CONFIG" > "$temp_file"; then
        mv "$temp_file" "$KEYBIND_CONFIG"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Function to delete binding
delete_binding() {
    local category="$1"
    local key="$2"
    local temp_file=$(mktemp)

    if jq "del(.categories.$category.bindings[\"$key\"])" "$KEYBIND_CONFIG" > "$temp_file"; then
        mv "$temp_file" "$KEYBIND_CONFIG"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Function to show category management
manage_categories() {
    local categories=($(get_categories))

    local menu_items=()
    for category in "${categories[@]}"; do
        local category_name=$(jq -r ".categories.$category.name" "$KEYBIND_CONFIG" 2>/dev/null)
        local binding_count=$(jq -r ".categories.$category.bindings | length" "$KEYBIND_CONFIG" 2>/dev/null)
        menu_items+=("📁 $category_name ($binding_count bindings)")
    done

    menu_items+=("➕ Add New Category" "🔙 Back to Main Menu")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "📁 Manage Categories" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "➕ Add New Category")
            create_new_category
            ;;
        "🔙 Back to Main Menu")
            return 0
            ;;
        *)
            if [[ "$selected" =~ ^📁\ (.+)\ \([0-9]+ ]]; then
                local category_display="${BASH_REMATCH[1]}"
                # Find category ID by display name
                local category_id=""
                for cat in "${categories[@]}"; do
                    local cat_name=$(jq -r ".categories.$cat.name" "$KEYBIND_CONFIG")
                    if [[ "$cat_name" == "$category_display" ]]; then
                        category_id="$cat"
                        break
                    fi
                done

                if [[ -n "$category_id" ]]; then
                    manage_category_bindings "$category_id"
                fi
            fi
            ;;
    esac
}

# Function to create new category
create_new_category() {
    local category_id=$(echo "" | rofi -dmenu -p "Enter category ID (lowercase, no spaces):")
    if [[ -z "$category_id" ]] || [[ ! "$category_id" =~ ^[a-z_]+$ ]]; then
        notify-send "❌ Invalid Category ID" "Use lowercase letters and underscores only" -t 3000
        return 1
    fi

    local category_name=$(echo "" | rofi -dmenu -p "Enter category display name:")
    if [[ -z "$category_name" ]]; then
        return 1
    fi

    local category_icon=$(echo "🔧" | rofi -dmenu -p "Enter category icon (emoji):")
    if [[ -z "$category_icon" ]]; then
        category_icon="🔧"
    fi

    local temp_file=$(mktemp)
    local category_json=$(jq -n \
        --arg name "$category_name" \
        --arg icon "$category_icon" \
        '{name: $name, icon: $icon, bindings: {}}')

    if jq ".categories.$category_id = $category_json" "$KEYBIND_CONFIG" > "$temp_file"; then
        mv "$temp_file" "$KEYBIND_CONFIG"
        notify-send "✅ Category Created" "Category '$category_name' created" -t 3000
    else
        rm -f "$temp_file"
        notify-send "❌ Error" "Failed to create category" -t 3000
    fi
}

# Function to manage bindings in a category
manage_category_bindings() {
    local category="$1"
    local category_name=$(jq -r ".categories.$category.name" "$KEYBIND_CONFIG")
    local bindings=($(get_category_bindings "$category"))

    local menu_items=()
    for binding in "${bindings[@]}"; do
        local description=$(get_binding_info "$category" "$binding" "description")
        local formatted_key=$(echo "$binding" | sed 's/SUPER/⊞/g; s/SHIFT/⇧/g; s/CTRL/⌃/g; s/ALT/⌥/g')
        menu_items+=("⌨️ $formatted_key → $description")
    done

    menu_items+=("➕ Add New Binding" "⚙️ Category Settings" "🔙 Back")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "⌨️ $category_name Bindings" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "➕ Add New Binding")
            add_binding_dialog "$category"
            ;;
        "⚙️ Category Settings")
            edit_category_settings "$category"
            ;;
        "🔙 Back")
            return 0
            ;;
        *)
            if [[ "$selected" =~ ^⌨️\ (.+)\ →\ (.+)$ ]]; then
                local key_display="${BASH_REMATCH[1]}"
                # Convert back to original format
                local original_key=$(echo "$key_display" | sed 's/⊞/SUPER/g; s/⇧/SHIFT/g; s/⌃/CTRL/g; s/⌥/ALT/g')
                edit_binding_dialog "$category" "$original_key"
            fi
            ;;
    esac

    # Return to same menu unless going back
    if [[ "$selected" != "🔙 Back" ]]; then
        manage_category_bindings "$category"
    fi
}

# Function to add binding dialog
add_binding_dialog() {
    local category="$1"

    local key_combo=$(echo "" | rofi -dmenu -p "Enter key combination (e.g., SUPER, RETURN):")
    if [[ -z "$key_combo" ]]; then
        return 1
    fi

    # Check if binding already exists
    if get_binding_info "$category" "$key_combo" "command" >/dev/null 2>&1; then
        notify-send "❌ Binding Exists" "Key combination already exists in this category" -t 3000
        return 1
    fi

    local command=$(echo "" | rofi -dmenu -p "Enter command to execute:")
    if [[ -z "$command" ]]; then
        return 1
    fi

    local description=$(echo "" | rofi -dmenu -p "Enter description:")
    if [[ -z "$description" ]]; then
        return 1
    fi

    local bind_type=$(rofi -dmenu -p "Select binding type:" <<< $'bind\nbindm\nbinde')
    if [[ -z "$bind_type" ]]; then
        bind_type="bind"
    fi

    if add_new_binding "$category" "$key_combo" "$command" "$description" "$bind_type"; then
        notify-send "✅ Binding Added" "Added $key_combo → $description" -t 3000

        # Ask if user wants to apply changes
        if rofi -dmenu -p "Apply changes now?" <<< $'Yes\nNo' | grep -q "Yes"; then
            apply_keybind_changes
        fi
    else
        notify-send "❌ Error" "Failed to add binding" -t 3000
    fi
}

# Function to edit binding dialog
edit_binding_dialog() {
    local category="$1"
    local key="$2"

    local current_command=$(get_binding_info "$category" "$key" "command")
    local current_description=$(get_binding_info "$category" "$key" "description")
    local current_type=$(get_binding_info "$category" "$key" "type")

    local options=(
        "✏️ Edit Key Combination"
        "⚙️ Edit Command"
        "📝 Edit Description"
        "🔧 Change Binding Type"
        "🧪 Test Binding"
        "🗑️ Delete Binding"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${options[@]}" | \
        rofi -dmenu -p "✏️ Edit $key" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "✏️ Edit Key Combination")
            local new_key=$(echo "$key" | rofi -dmenu -p "Enter new key combination:")
            if [[ -n "$new_key" && "$new_key" != "$key" ]]; then
                # Copy binding to new key and delete old one
                local temp_file=$(mktemp)
                local binding_data=$(jq ".categories.$category.bindings[\"$key\"]" "$KEYBIND_CONFIG")

                if jq ".categories.$category.bindings[\"$new_key\"] = $binding_data | del(.categories.$category.bindings[\"$key\"])" "$KEYBIND_CONFIG" > "$temp_file"; then
                    mv "$temp_file" "$KEYBIND_CONFIG"
                    notify-send "✅ Key Updated" "Binding moved to $new_key" -t 3000
                else
                    rm -f "$temp_file"
                    notify-send "❌ Error" "Failed to update key" -t 3000
                fi
            fi
            ;;
        "⚙️ Edit Command")
            local new_command=$(echo "$current_command" | rofi -dmenu -p "Enter new command:")
            if [[ -n "$new_command" ]]; then
                set_binding_info "$category" "$key" "command" "$new_command"
                notify-send "✅ Command Updated" "Command updated to: $new_command" -t 3000
            fi
            ;;
        "📝 Edit Description")
            local new_description=$(echo "$current_description" | rofi -dmenu -p "Enter new description:")
            if [[ -n "$new_description" ]]; then
                set_binding_info "$category" "$key" "description" "$new_description"
                notify-send "✅ Description Updated" "Description updated" -t 3000
            fi
            ;;
        "🔧 Change Binding Type")
            local new_type=$(rofi -dmenu -p "Select binding type:" <<< $'bind\nbindm\nbinde')
            if [[ -n "$new_type" ]]; then
                set_binding_info "$category" "$key" "type" "$new_type"
                notify-send "✅ Type Updated" "Binding type set to $new_type" -t 3000
            fi
            ;;
        "🧪 Test Binding")
            test_binding "$current_command"
            ;;
        "🗑️ Delete Binding")
            if rofi -dmenu -p "Delete binding $key?" <<< $'Yes\nNo' | grep -q "Yes"; then
                delete_binding "$category" "$key"
                notify-send "🗑️ Binding Deleted" "Removed $key binding" -t 3000
                return 0  # Exit to category menu
            fi
            ;;
        "🔙 Back")
            return 0
            ;;
    esac

    # Return to edit dialog unless deleting or going back
    if [[ "$selected" != "🗑️ Delete Binding" && "$selected" != "🔙 Back" ]]; then
        edit_binding_dialog "$category" "$key"
    fi
}

# Function to test binding
test_binding() {
    local command="$1"

    notify-send "🧪 Testing Binding" "Executing: $command" -t 3000

    # Execute command in background
    if [[ "$command" == "exec,"* ]]; then
        # Handle Hyprland exec format
        local actual_command="${command#exec, }"
        eval "$actual_command" &
    else
        # Handle Hyprland dispatcher
        hyprctl dispatch $command 2>/dev/null || notify-send "❌ Test Failed" "Command execution failed" -t 3000
    fi
}

# Function to edit category settings
edit_category_settings() {
    local category="$1"
    local current_name=$(jq -r ".categories.$category.name" "$KEYBIND_CONFIG")
    local current_icon=$(jq -r ".categories.$category.icon" "$KEYBIND_CONFIG")

    local options=(
        "📝 Edit Category Name"
        "🎨 Change Icon"
        "🗑️ Delete Category"
        "🔙 Back"
    )

    local selected=$(printf '%s\n' "${options[@]}" | \
        rofi -dmenu -p "⚙️ $current_name Settings" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "📝 Edit Category Name")
            local new_name=$(echo "$current_name" | rofi -dmenu -p "Enter new category name:")
            if [[ -n "$new_name" ]]; then
                local temp_file=$(mktemp)
                jq ".categories.$category.name = \"$new_name\"" "$KEYBIND_CONFIG" > "$temp_file" && mv "$temp_file" "$KEYBIND_CONFIG"
                notify-send "✅ Name Updated" "Category renamed to $new_name" -t 3000
            fi
            ;;
        "🎨 Change Icon")
            local new_icon=$(echo "$current_icon" | rofi -dmenu -p "Enter new icon (emoji):")
            if [[ -n "$new_icon" ]]; then
                local temp_file=$(mktemp)
                jq ".categories.$category.icon = \"$new_icon\"" "$KEYBIND_CONFIG" > "$temp_file" && mv "$temp_file" "$KEYBIND_CONFIG"
                notify-send "✅ Icon Updated" "Category icon changed to $new_icon" -t 3000
            fi
            ;;
        "🗑️ Delete Category")
            local binding_count=$(jq -r ".categories.$category.bindings | length" "$KEYBIND_CONFIG")
            if [[ "$binding_count" -gt 0 ]]; then
                notify-send "❌ Cannot Delete" "Category has $binding_count bindings. Remove them first." -t 5000
            else
                if rofi -dmenu -p "Delete category $current_name?" <<< $'Yes\nNo' | grep -q "Yes"; then
                    local temp_file=$(mktemp)
                    jq "del(.categories.$category)" "$KEYBIND_CONFIG" > "$temp_file" && mv "$temp_file" "$KEYBIND_CONFIG"
                    notify-send "🗑️ Category Deleted" "Category $current_name removed" -t 3000
                    return 0  # Exit to main menu
                fi
            fi
            ;;
    esac
}

# Function to search bindings
search_bindings() {
    local search_term=$(echo "" | rofi -dmenu -p "🔍 Search bindings (key or description):")
    if [[ -z "$search_term" ]]; then
        return 1
    fi

    local results=()
    local categories=($(get_categories))

    for category in "${categories[@]}"; do
        local category_name=$(jq -r ".categories.$category.name" "$KEYBIND_CONFIG")
        local bindings=($(get_category_bindings "$category"))

        for binding in "${bindings[@]}"; do
            local description=$(get_binding_info "$category" "$binding" "description")
            local command=$(get_binding_info "$category" "$binding" "command")

            if [[ "$binding" =~ $search_term ]] || [[ "$description" =~ $search_term ]] || [[ "$command" =~ $search_term ]]; then
                local formatted_key=$(echo "$binding" | sed 's/SUPER/⊞/g; s/SHIFT/⇧/g; s/CTRL/⌃/g; s/ALT/⌥/g')
                results+=("⌨️ $formatted_key → $description [$category_name]")
            fi
        done
    done

    if [[ ${#results[@]} -eq 0 ]]; then
        notify-send "🔍 No Results" "No bindings found matching '$search_term'" -t 3000
        return 1
    fi

    local selected=$(printf '%s\n' "${results[@]}" | \
        rofi -dmenu -p "🔍 Search Results" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected" ]]; then
        notify-send "🔍 Search Result" "$selected" -t 5000
    fi
}

# Function to apply keybind changes
apply_keybind_changes() {
    notify-send "🔄 Applying Changes" "Regenerating keybinding configuration..." -t 3000

    if [[ -f "$SCRIPT_DIR/generators/apply-theme.py" ]]; then
        cd "$SCRIPT_DIR" && python3 generators/apply-theme.py

        # Reload Hyprland to apply new bindings
        hyprctl reload

        notify-send "✅ Changes Applied" "Keybindings updated successfully" -t 3000
    else
        notify-send "❌ Error" "Theme generator not found" -t 5000 -u critical
    fi
}

# Function to show binding conflicts
check_conflicts() {
    local conflicts=()
    local all_bindings=()
    local categories=($(get_categories))

    # Collect all bindings
    for category in "${categories[@]}"; do
        local bindings=($(get_category_bindings "$category"))
        for binding in "${bindings[@]}"; do
            all_bindings+=("$binding:$category")
        done
    done

    # Check for duplicates
    local seen=()
    for binding_info in "${all_bindings[@]}"; do
        local binding="${binding_info%:*}"
        local category="${binding_info#*:}"

        for seen_binding in "${seen[@]}"; do
            if [[ "$seen_binding" == "$binding:*" ]]; then
                conflicts+=("⚠️ $binding (conflicts between categories)")
                break
            fi
        done

        seen+=("$binding:$category")
    done

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        notify-send "✅ No Conflicts" "All keybindings are unique" -t 3000
    else
        printf '%s\n' "${conflicts[@]}" | \
            rofi -dmenu -p "⚠️ Binding Conflicts" \
            -theme "$ROFI_THEME" -no-custom
    fi
}

# Main keybind editor menu
show_keybind_editor() {
    local main_menu=(
        "📁 Manage Categories"
        "🔍 Search Bindings"
        "⚠️ Check Conflicts"
        "🔄 Apply Changes"
        "📄 Export Bindings"
        "📥 Import Bindings"
        "💾 Save & Exit"
    )

    local selected=$(printf '%s\n' "${main_menu[@]}" | \
        rofi -dmenu -p "⌨️ Keybinding Editor" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    case "$selected" in
        "📁 Manage Categories")
            manage_categories
            ;;
        "🔍 Search Bindings")
            search_bindings
            ;;
        "⚠️ Check Conflicts")
            check_conflicts
            ;;
        "🔄 Apply Changes")
            apply_keybind_changes
            ;;
        "📄 Export Bindings")
            export_bindings
            ;;
        "📥 Import Bindings")
            import_bindings
            ;;
        "💾 Save & Exit")
            apply_keybind_changes
            return 0
            ;;
        *)
            return 0
            ;;
    esac

    # Return to main menu unless exiting
    show_keybind_editor
}

# Function to export bindings
export_bindings() {
    local export_file="$HOME/Desktop/keybindings-$(date +%Y%m%d_%H%M%S).json"

    if cp "$KEYBIND_CONFIG" "$export_file"; then
        notify-send "📄 Bindings Exported" "Exported to $export_file" -t 3000
    else
        notify-send "❌ Export Failed" "Could not export bindings" -t 3000
    fi
}

# Function to import bindings
import_bindings() {
    local import_file=$(echo "" | rofi -dmenu -p "Enter path to keybinding file:")
    if [[ -z "$import_file" || ! -f "$import_file" ]]; then
        notify-send "❌ Import Failed" "File not found or invalid" -t 3000
        return 1
    fi

    # Validate JSON
    if ! jq empty "$import_file" 2>/dev/null; then
        notify-send "❌ Invalid File" "File is not valid JSON" -t 3000
        return 1
    fi

    if rofi -dmenu -p "This will replace all current bindings. Continue?" <<< $'Yes\nNo' | grep -q "Yes"; then
        cp "$import_file" "$KEYBIND_CONFIG"
        notify-send "📥 Bindings Imported" "Keybindings imported successfully" -t 3000
        apply_keybind_changes
    fi
}

# Main function
main() {
    if ! check_dependencies; then
        exit 1
    fi

    case "${1:-menu}" in
        "menu")
            show_keybind_editor
            ;;
        "categories")
            manage_categories
            ;;
        "search")
            search_bindings
            ;;
        "conflicts")
            check_conflicts
            ;;
        "apply")
            apply_keybind_changes
            ;;
        *)
            echo "⌨️ Keybinding Editor"
            echo ""
            echo "Usage: $0 {menu|categories|search|conflicts|apply}"
            echo ""
            echo "Commands:"
            echo "  menu        - Show main keybinding editor menu"
            echo "  categories  - Manage binding categories"
            echo "  search      - Search existing bindings"
            echo "  conflicts   - Check for binding conflicts"
            echo "  apply       - Apply keybinding changes"
            ;;
    esac
}

# Run main function
main "$@"
