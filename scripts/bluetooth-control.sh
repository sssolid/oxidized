#!/bin/bash
# 🔵 Advanced Bluetooth Control with Cyberpunk Interface

ROFI_THEME="$HOME/.config/rofi/themes/cyberpunk-medieval.rasi"

# Colors for notifications
CYAN="#00ffff"
BLUE="#0080ff"
GOLD="#ffd700"
CRIMSON="#dc143c"
GREEN="#39ff14"

# Function to check if Bluetooth is available
check_bluetooth() {
    if ! command -v bluetoothctl >/dev/null 2>&1; then
        notify-send "❌ Bluetooth Error" \
            "bluetoothctl not found. Please install bluez-utils." \
            -t 5000 -u critical
        return 1
    fi

    if ! systemctl is-active --quiet bluetooth; then
        notify-send "🔵 Bluetooth Service" \
            "Starting Bluetooth service..." \
            -t 3000 -u normal
        sudo systemctl start bluetooth
        sleep 2
    fi

    return 0
}

# Function to get Bluetooth power status
get_bluetooth_status() {
    bluetoothctl show | grep -q "Powered: yes" && echo "on" || echo "off"
}

# Function to toggle Bluetooth power
toggle_bluetooth() {
    local status=$(get_bluetooth_status)

    if [[ "$status" == "on" ]]; then
        bluetoothctl power off
        notify-send "🔵 Bluetooth Disabled" \
            "Bluetooth has been turned off" \
            -t 3000 -u normal
    else
        bluetoothctl power on
        notify-send "🔵 Bluetooth Enabled" \
            "Bluetooth has been turned on" \
            -t 3000 -u normal
    fi

    # Update Waybar
    pkill -RTMIN+10 waybar 2>/dev/null || true
}

# Function to get paired devices
get_paired_devices() {
    bluetoothctl devices Paired | while read -r line; do
        local mac=$(echo "$line" | awk '{print $2}')
        local name=$(echo "$line" | cut -d' ' -f3-)
        local connected=""

        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            connected="✅"
        else
            connected="❌"
        fi

        echo "$connected $name|$mac"
    done
}

# Function to get available devices (scanning)
get_available_devices() {
    echo "🔍 Scanning for devices..."
    bluetoothctl scan on &
    local scan_pid=$!

    # Scan for 10 seconds
    sleep 10
    kill $scan_pid 2>/dev/null

    bluetoothctl devices | while read -r line; do
        local mac=$(echo "$line" | awk '{print $2}')
        local name=$(echo "$line" | cut -d' ' -f3-)
        local paired=""

        if bluetoothctl devices Paired | grep -q "$mac"; then
            paired="[Paired]"
        else
            paired="[Available]"
        fi

        echo "$paired $name|$mac"
    done
}

# Function to connect to device
connect_device() {
    local mac="$1"
    local name="$2"

    notify-send "🔵 Connecting..." \
        "Connecting to $name..." \
        -t 3000 -u normal

    # Try to connect
    if bluetoothctl connect "$mac"; then
        notify-send "✅ Connected" \
            "Successfully connected to $name" \
            -t 3000 -u normal

        # Play connection sound if available
        if command -v paplay >/dev/null 2>&1 && [[ -f "/usr/share/sounds/freedesktop/stereo/device-added.oga" ]]; then
            paplay /usr/share/sounds/freedesktop/stereo/device-added.oga 2>/dev/null &
        fi
    else
        notify-send "❌ Connection Failed" \
            "Failed to connect to $name" \
            -t 5000 -u critical
    fi

    # Update Waybar
    pkill -RTMIN+10 waybar 2>/dev/null || true
}

# Function to disconnect device
disconnect_device() {
    local mac="$1"
    local name="$2"

    notify-send "🔵 Disconnecting..." \
        "Disconnecting from $name..." \
        -t 3000 -u normal

    if bluetoothctl disconnect "$mac"; then
        notify-send "❌ Disconnected" \
            "Disconnected from $name" \
            -t 3000 -u normal

        # Play disconnection sound if available
        if command -v paplay >/dev/null 2>&1 && [[ -f "/usr/share/sounds/freedesktop/stereo/device-removed.oga" ]]; then
            paplay /usr/share/sounds/freedesktop/stereo/device-removed.oga 2>/dev/null &
        fi
    else
        notify-send "❌ Disconnection Failed" \
            "Failed to disconnect from $name" \
            -t 5000 -u critical
    fi

    # Update Waybar
    pkill -RTMIN+10 waybar 2>/dev/null || true
}

# Function to pair with device
pair_device() {
    local mac="$1"
    local name="$2"

    notify-send "🔵 Pairing..." \
        "Pairing with $name..." \
        -t 5000 -u normal

    # Make device discoverable and pairable
    bluetoothctl discoverable on
    bluetoothctl pairable on

    if bluetoothctl pair "$mac"; then
        notify-send "✅ Paired" \
            "Successfully paired with $name" \
            -t 3000 -u normal

        # Auto-connect after pairing
        connect_device "$mac" "$name"
    else
        notify-send "❌ Pairing Failed" \
            "Failed to pair with $name" \
            -t 5000 -u critical
    fi
}

# Function to unpair device
unpair_device() {
    local mac="$1"
    local name="$2"

    # Disconnect first if connected
    bluetoothctl disconnect "$mac" 2>/dev/null

    if bluetoothctl remove "$mac"; then
        notify-send "🗑️ Device Removed" \
            "Removed $name from paired devices" \
            -t 3000 -u normal
    else
        notify-send "❌ Removal Failed" \
            "Failed to remove $name" \
            -t 5000 -u critical
    fi
}

# Function to show device menu
show_device_menu() {
    local devices=($(get_paired_devices))

    if [[ ${#devices[@]} -eq 0 ]]; then
        notify-send "🔵 No Paired Devices" \
            "No paired devices found. Use 'Scan for Devices' to find new devices." \
            -t 5000 -u normal
        return 1
    fi

    # Add control options
    local menu_items=()

    # Add paired devices
    for device in "${devices[@]}"; do
        IFS='|' read -r display mac <<< "$device"
        menu_items+=("$display")
    done

    # Add control options
    menu_items+=("🔍 Scan for New Devices" "🔧 Bluetooth Settings" "📱 Device Manager")

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🔵 Bluetooth Devices" \
        -theme "$ROFI_THEME" \
        -markup-rows)

    if [[ -n "$selected" ]]; then
        case "$selected" in
            "🔍 Scan for New Devices")
                show_scan_menu
                ;;
            "🔧 Bluetooth Settings")
                if command -v blueman-manager >/dev/null 2>&1; then
                    blueman-manager &
                else
                    notify-send "❌ Settings" "blueman-manager not found" -t 3000
                fi
                ;;
            "📱 Device Manager")
                show_device_manager
                ;;
            *)
                # Handle device selection
                for device in "${devices[@]}"; do
                    IFS='|' read -r display mac <<< "$device"
                    if [[ "$display" == "$selected" ]]; then
                        show_device_actions "$mac" "$display"
                        break
                    fi
                done
                ;;
        esac
    fi
}

# Function to show device actions
show_device_actions() {
    local mac="$1"
    local display="$2"
    local name=$(echo "$display" | sed 's/^[✅❌] //')

    local actions=()

    # Determine available actions based on connection status
    if echo "$display" | grep -q "✅"; then
        actions+=("❌ Disconnect" "🔊 Audio Settings" "ℹ️ Device Info")
    else
        actions+=("✅ Connect" "ℹ️ Device Info")
    fi

    actions+=("🗑️ Unpair Device" "🔄 Reconnect")

    local selected_action=$(printf '%s\n' "${actions[@]}" | \
        rofi -dmenu -p "🔵 $name" \
        -theme "$ROFI_THEME")

    case "$selected_action" in
        "✅ Connect")
            connect_device "$mac" "$name"
            ;;
        "❌ Disconnect")
            disconnect_device "$mac" "$name"
            ;;
        "🗑️ Unpair Device")
            unpair_device "$mac" "$name"
            ;;
        "🔄 Reconnect")
            disconnect_device "$mac" "$name"
            sleep 2
            connect_device "$mac" "$name"
            ;;
        "🔊 Audio Settings")
            if command -v pavucontrol >/dev/null 2>&1; then
                pavucontrol &
            else
                notify-send "❌ Audio Settings" "pavucontrol not found" -t 3000
            fi
            ;;
        "ℹ️ Device Info")
            show_device_info "$mac" "$name"
            ;;
    esac
}

# Function to show device info
show_device_info() {
    local mac="$1"
    local name="$2"

    local info=$(bluetoothctl info "$mac")
    local connected=$(echo "$info" | grep "Connected:" | awk '{print $2}')
    local paired=$(echo "$info" | grep "Paired:" | awk '{print $2}')
    local battery=""

    # Try to get battery level
    if echo "$info" | grep -q "Battery Percentage"; then
        battery=$(echo "$info" | grep "Battery Percentage" | awk '{print $4}' | tr -d '()')
        battery="🔋 Battery: $battery%"
    fi

    local info_text="Device: $name\nMAC: $mac\nConnected: $connected\nPaired: $paired"
    if [[ -n "$battery" ]]; then
        info_text="$info_text\n$battery"
    fi

    notify-send "ℹ️ Device Information" \
        "$info_text" \
        -t 10000 -u normal
}

# Function to show scan menu
show_scan_menu() {
    notify-send "🔍 Scanning..." \
        "Scanning for Bluetooth devices..." \
        -t 3000 -u normal

    local devices=($(get_available_devices))

    if [[ ${#devices[@]} -eq 0 ]]; then
        notify-send "🔍 No Devices Found" \
            "No Bluetooth devices found nearby" \
            -t 5000 -u normal
        return 1
    fi

    local selected=$(printf '%s\n' "${devices[@]}" | \
        awk -F'|' '{print $1}' | \
        rofi -dmenu -p "🔍 Available Devices" \
        -theme "$ROFI_THEME")

    if [[ -n "$selected" ]]; then
        # Find MAC address for selected device
        for device in "${devices[@]}"; do
            IFS='|' read -r display mac <<< "$device"
            if [[ "$display" == "$selected" ]]; then
                local name=$(echo "$display" | sed 's/^\[.*\] //')
                if echo "$display" | grep -q "\[Available\]"; then
                    pair_device "$mac" "$name"
                else
                    connect_device "$mac" "$name"
                fi
                break
            fi
        done
    fi
}

# Function to show device manager
show_device_manager() {
    local bluetooth_status=$(get_bluetooth_status)
    local status_icon=""

    if [[ "$bluetooth_status" == "on" ]]; then
        status_icon="✅ Bluetooth: ON"
    else
        status_icon="❌ Bluetooth: OFF"
    fi

    local manager_options=(
        "$status_icon"
        "🔄 Toggle Bluetooth"
        "🔍 Scan for Devices"
        "📋 Show All Devices"
        "🧹 Clear Device Cache"
        "🔧 Open Bluetooth Settings"
        "📊 Bluetooth Status"
    )

    local selected=$(printf '%s\n' "${manager_options[@]}" | \
        rofi -dmenu -p "📱 Bluetooth Manager" \
        -theme "$ROFI_THEME")

    case "$selected" in
        "🔄 Toggle Bluetooth")
            toggle_bluetooth
            ;;
        "🔍 Scan for Devices")
            show_scan_menu
            ;;
        "📋 Show All Devices")
            show_device_menu
            ;;
        "🧹 Clear Device Cache")
            sudo systemctl restart bluetooth
            notify-send "🧹 Cache Cleared" "Bluetooth cache cleared" -t 3000
            ;;
        "🔧 Open Bluetooth Settings")
            if command -v blueman-manager >/dev/null 2>&1; then
                blueman-manager &
            else
                notify-send "❌ Settings" "blueman-manager not found" -t 3000
            fi
            ;;
        "📊 Bluetooth Status")
            local status_info="Bluetooth Status: $bluetooth_status\nService: $(systemctl is-active bluetooth)"
            notify-send "📊 Bluetooth Status" "$status_info" -t 5000
            ;;
    esac
}

# Function to get status for waybar
get_waybar_status() {
    local bluetooth_status=$(get_bluetooth_status)

    if [[ "$bluetooth_status" == "off" ]]; then
        echo '{"text": "🔵", "class": "disabled", "tooltip": "Bluetooth disabled"}'
        return
    fi

    local connected_devices=$(bluetoothctl devices Connected | wc -l)

    if [[ $connected_devices -gt 0 ]]; then
        local device_name=$(bluetoothctl devices Connected | head -1 | cut -d' ' -f3-)
        echo "{\"text\": \"🔵 $connected_devices\", \"class\": \"connected\", \"tooltip\": \"Connected: $device_name\"}"
    else
        echo '{"text": "🔵", "class": "disconnected", "tooltip": "Bluetooth on, no devices connected"}'
    fi
}

# Main script logic
main() {
    if ! check_bluetooth; then
        exit 1
    fi

    case "$1" in
        menu)
            show_device_menu
            ;;
        toggle)
            toggle_bluetooth
            ;;
        scan)
            show_scan_menu
            ;;
        connect)
            if [[ -n "$2" ]]; then
                connect_device "$2" "${3:-Unknown Device}"
            else
                echo "Usage: $0 connect <mac_address> [device_name]"
            fi
            ;;
        disconnect)
            if [[ -n "$2" ]]; then
                disconnect_device "$2" "${3:-Unknown Device}"
            else
                echo "Usage: $0 disconnect <mac_address> [device_name]"
            fi
            ;;
        status)
            get_bluetooth_status
            ;;
        waybar)
            get_waybar_status
            ;;
        *)
            echo "🔵 Cyberpunk Bluetooth Control"
            echo ""
            echo "Usage: $0 {menu|toggle|scan|connect|disconnect|status|waybar}"
            echo ""
            echo "Commands:"
            echo "  menu              - Show device menu"
            echo "  toggle            - Toggle Bluetooth on/off"
            echo "  scan              - Scan for available devices"
            echo "  connect <mac>     - Connect to device"
            echo "  disconnect <mac>  - Disconnect from device"
            echo "  status            - Show Bluetooth status"
            echo "  waybar            - Output status for Waybar"
            echo ""
            echo "Default action: show device menu"
            show_device_menu
            ;;
    esac
}

# Run main function
main "$@"
