#!/bin/bash
# 🌐 ZeroTier VPN Status Monitor
# Provides status information for Waybar and system monitoring

# Check if ZeroTier is installed
if ! command -v sudo zerotier-cli >/dev/null 2>&1; then
    echo "N/A"
    exit 0
fi

# Check if ZeroTier service is running
if ! systemctl is-active --quiet zerotier-one; then
    echo "Offline"
    exit 0
fi

# Function to get ZeroTier status
get_zerotier_status() {
    local status_output
    status_output=$(sudo zerotier-cli info 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        echo "Error"
        return 1
    fi

    # Parse status
    local node_id=$(echo "$status_output" | awk '{print $3}')
    local version=$(echo "$status_output" | awk '{print $4}')
    local status=$(echo "$status_output" | awk '{print $5}')

    # Get network information
    local networks_output
    networks_output=$(zerotier-cli listnetworks 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        echo "Connected"
        return 0
    fi

    # Count connected networks
    local connected_count=0
    local total_count=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[0-9a-f]{16} ]]; then
            total_count=$((total_count + 1))
            if echo "$line" | grep -q "OK"; then
                connected_count=$((connected_count + 1))
            fi
        fi
    done <<< "$networks_output"

    if [[ $connected_count -gt 0 ]]; then
        echo "$connected_count"
    else
        echo "0"
    fi
}

# Function to get detailed status for tooltip
get_detailed_status() {
    local info_output
    info_output=$(sudo zerotier-cli info 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        echo "ZeroTier: Service Error"
        return 1
    fi

    local node_id=$(echo "$info_output" | awk '{print $3}')
    local version=$(echo "$info_output" | awk '{print $4}')
    local status=$(echo "$info_output" | awk '{print $5}')

    local networks_output
    networks_output=$(sudo zerotier-cli listnetworks 2>/dev/null)

    echo "ZeroTier Node: ${node_id:0:10}..."
    echo "Version: $version"
    echo "Status: $status"
    echo ""

    if [[ $? -eq 0 ]] && [[ -n "$networks_output" ]]; then
        echo "Networks:"
        while IFS= read -r line; do
            if [[ "$line" =~ ^[0-9a-f]{16} ]]; then
                local net_id=$(echo "$line" | awk '{print $1}')
                local net_name=$(echo "$line" | awk '{print $2}')
                local net_status=$(echo "$line" | awk '{print $4}')
                local net_type=$(echo "$line" | awk '{print $5}')
                local net_ip=$(echo "$line" | awk '{print $7}')

                echo "  ${net_name:-Unknown} (${net_id:0:8}...)"
                echo "    Status: $net_status"
                if [[ -n "$net_ip" && "$net_ip" != "-" ]]; then
                    echo "    IP: $net_ip"
                fi
            fi
        done <<< "$networks_output"
    else
        echo "No networks configured"
    fi
}

# Function to get JSON output for Waybar
get_json_status() {
    local status=$(get_zerotier_status)
    local class="disconnected"
    local tooltip="ZeroTier: Not connected"

    case "$status" in
        "N/A")
            echo '{"text": "", "class": "disabled", "tooltip": "ZeroTier not installed"}'
            return
            ;;
        "Offline")
            echo '{"text": "🌐", "class": "offline", "tooltip": "ZeroTier service offline"}'
            return
            ;;
        "Error")
            echo '{"text": "🌐", "class": "error", "tooltip": "ZeroTier service error"}'
            return
            ;;
        "0")
            class="disconnected"
            tooltip="ZeroTier: No networks connected"
            ;;
        *)
            if [[ "$status" =~ ^[0-9]+$ ]]; then
                class="connected"
                if [[ "$status" -eq 1 ]]; then
                    tooltip="ZeroTier: 1 network connected"
                else
                    tooltip="ZeroTier: $status networks connected"
                fi
            fi
            ;;
    esac

    # Get detailed tooltip
    local detailed_tooltip
    detailed_tooltip=$(get_detailed_status | tr '\n' '\\n')

    echo "{\"text\": \"🌐 $status\", \"class\": \"$class\", \"tooltip\": \"$detailed_tooltip\"}"
}

# Function to control ZeroTier
control_zerotier() {
    local action="$1"

    case "$action" in
        "start")
            sudo systemctl start zerotier-one
            notify-send "🌐 ZeroTier" "Starting ZeroTier service..." -t 3000
            ;;
        "stop")
            sudo systemctl stop zerotier-one
            notify-send "🌐 ZeroTier" "Stopping ZeroTier service..." -t 3000
            ;;
        "restart")
            sudo systemctl restart zerotier-one
            notify-send "🌐 ZeroTier" "Restarting ZeroTier service..." -t 3000
            ;;
        "join")
            if [[ -n "$2" ]]; then
                sudo zerotier-cli join "$2"
                notify-send "🌐 ZeroTier" "Joining network $2..." -t 3000
            else
                echo "Usage: $0 control join <network_id>"
            fi
            ;;
        "leave")
            if [[ -n "$2" ]]; then
                sudo zerotier-cli leave "$2"
                notify-send "🌐 ZeroTier" "Leaving network $2..." -t 3000
            else
                echo "Usage: $0 control leave <network_id>"
            fi
            ;;
        *)
            echo "Usage: $0 control {start|stop|restart|join <id>|leave <id>}"
            ;;
    esac
}

# Function to show network management menu
show_network_menu() {
    if ! command -v rofi >/dev/null 2>&1; then
        echo "Rofi not found"
        return 1
    fi

    local networks_output
    networks_output=$(zerotier-cli listnetworks 2>/dev/null)

    local menu_items=()

    # Add service controls
    if systemctl is-active --quiet zerotier-one; then
        menu_items+=("🔴 Stop ZeroTier Service")
        menu_items+=("🔄 Restart ZeroTier Service")
    else
        menu_items+=("🟢 Start ZeroTier Service")
    fi

    menu_items+=("➕ Join Network")
    menu_items+=("ℹ️ Show Node Info")

    # Add existing networks
    if [[ $? -eq 0 ]] && [[ -n "$networks_output" ]]; then
        menu_items+=("" "📡 Networks:")

        while IFS= read -r line; do
            if [[ "$line" =~ ^[0-9a-f]{16} ]]; then
                local net_id=$(echo "$line" | awk '{print $1}')
                local net_name=$(echo "$line" | awk '{print $2}')
                local net_status=$(echo "$line" | awk '{print $3}')

                local status_icon="❌"
                if [[ "$net_status" == "OK" ]]; then
                    status_icon="✅"
                fi

                menu_items+=("$status_icon ${net_name:-$net_id}")
            fi
        done <<< "$networks_output"
    fi

    local selected=$(printf '%s\n' "${menu_items[@]}" | \
        rofi -dmenu -p "🌐 ZeroTier" \
        -theme "$HOME/.config/rofi/themes/cyberpunk-medieval.rasi" \
        -markup-rows)

    case "$selected" in
        "🟢 Start ZeroTier Service")
            control_zerotier "start"
            ;;
        "🔴 Stop ZeroTier Service")
            control_zerotier "stop"
            ;;
        "🔄 Restart ZeroTier Service")
            control_zerotier "restart"
            ;;
        "➕ Join Network")
            local network_id=$(echo "" | rofi -dmenu -p "Enter Network ID:")
            if [[ -n "$network_id" ]]; then
                control_zerotier "join" "$network_id"
            fi
            ;;
        "ℹ️ Show Node Info")
            get_detailed_status | rofi -dmenu -p "🌐 ZeroTier Info" -no-custom
            ;;
        *)
            # Handle network selection
            if [[ "$selected" =~ ^[✅❌] ]]; then
                local net_name=$(echo "$selected" | sed 's/^[✅❌] //')
                # Find network ID by name
                local net_id=$(sudo zerotier-cli listnetworks | grep "$net_name" | awk '{print $1}')
                if [[ -n "$net_id" ]]; then
                    local actions=("📊 Network Info" "❌ Leave Network")
                    local action=$(printf '%s\n' "${actions[@]}" | \
                        rofi -dmenu -p "🌐 $net_name")

                    case "$action" in
                        "📊 Network Info")
                            sudo zerotier-cli listnetworks | grep "$net_id" | rofi -dmenu -p "Network Info" -no-custom
                            ;;
                        "❌ Leave Network")
                            control_zerotier "leave" "$net_id"
                            ;;
                    esac
                fi
            fi
            ;;
    esac
}

# Main function
main() {
    case "${1:-status}" in
        "status")
            get_zerotier_status
            ;;
        "detailed")
            get_detailed_status
            ;;
        "json")
            get_json_status
            ;;
        "menu")
            show_network_menu
            ;;
        "control")
            shift
            control_zerotier "$@"
            ;;
        *)
            echo "🌐 ZeroTier Status Monitor"
            echo ""
            echo "Usage: $0 {status|detailed|json|menu|control}"
            echo ""
            echo "Commands:"
            echo "  status    - Show connection count"
            echo "  detailed  - Show detailed status"
            echo "  json      - JSON output for Waybar"
            echo "  menu      - Show management menu"
            echo "  control   - Control ZeroTier service"
            ;;
    esac
}

# Run main function
main "$@"
