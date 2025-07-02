#!/bin/bash
# 🔊 Advanced Volume Control with Cyberpunk Notifications

# Get theme colors from config
THEME_CONFIG="$HOME/.config/hypr-system/core/theme-config.json"
CYAN="#00ffff"
GOLD="#ffd700"
CRIMSON="#dc143c"

# Function to get current volume info
get_volume_info() {
    if command -v wpctl >/dev/null 2>&1; then
        # Use wireplumber (modern)
        volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
        muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED" || echo "")
    elif command -v pamixer >/dev/null 2>&1; then
        # Use pamixer (alternative)
        volume=$(pamixer --get-volume)
        muted=$(pamixer --get-mute && echo "MUTED" || echo "")
    else
        # Fallback to amixer
        volume=$(amixer get Master | grep -o '[0-9]*%' | head -1 | tr -d '%')
        muted=$(amixer get Master | grep -o '\[off\]' && echo "MUTED" || echo "")
    fi

    echo "$volume|$muted"
}

# Function to set volume
set_volume() {
    local action="$1"

    if command -v wpctl >/dev/null 2>&1; then
        case $action in
            up)
                wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
                ;;
            down)
                wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
                ;;
            mute)
                wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
                ;;
            set)
                local target_volume="$2"
                wpctl set-volume @DEFAULT_AUDIO_SINK@ "${target_volume}%"
                ;;
        esac
    elif command -v pamixer >/dev/null 2>&1; then
        case $action in
            up)
                pamixer -i 5
                ;;
            down)
                pamixer -d 5
                ;;
            mute)
                pamixer -t
                ;;
            set)
                local target_volume="$2"
                pamixer --set-volume "$target_volume"
                ;;
        esac
    else
        case $action in
            up)
                amixer set Master 5%+
                ;;
            down)
                amixer set Master 5%-
                ;;
            mute)
                amixer set Master toggle
                ;;
            set)
                local target_volume="$2"
                amixer set Master "${target_volume}%"
                ;;
        esac
    fi
}

# Function to show notification
show_notification() {
    local volume="$1"
    local muted="$2"

    if [[ -n "$muted" ]]; then
        # Muted notification
        notify-send "🔇 Audio Muted" \
            -t 1500 \
            -h int:value:0 \
            -h string:x-canonical-private-synchronous:volume \
            -u normal
    else
        # Volume notification with appropriate icon
        local icon volume_bar
        if [[ $volume -le 0 ]]; then
            icon="🔈"
        elif [[ $volume -le 30 ]]; then
            icon="🔉"
        elif [[ $volume -le 70 ]]; then
            icon="🔊"
        else
            icon="📢"
        fi

        # Create visual volume bar
        local bar_length=20
        local filled_length=$((volume * bar_length / 100))
        volume_bar=""

        for ((i=0; i<filled_length; i++)); do
            volume_bar+="█"
        done

        for ((i=filled_length; i<bar_length; i++)); do
            volume_bar+="░"
        done

        notify-send "$icon Volume: $volume%" \
            "$volume_bar" \
            -t 1500 \
            -h int:value:"$volume" \
            -h string:x-canonical-private-synchronous:volume \
            -u normal
    fi
}

# Function to play sound feedback
play_feedback() {
    local action="$1"

    # Only play sounds if not muted and sounds are available
    if command -v paplay >/dev/null 2>&1; then
        case $action in
            up|down)
                if [[ -f "/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga" ]]; then
                    paplay /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga 2>/dev/null &
                fi
                ;;
            mute)
                if [[ -f "/usr/share/sounds/freedesktop/stereo/audio-volume-mute.oga" ]]; then
                    paplay /usr/share/sounds/freedesktop/stereo/audio-volume-mute.oga 2>/dev/null &
                fi
                ;;
        esac
    fi
}

# Function to update waybar
update_waybar() {
    # Send signal to waybar to update audio module
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

# Function to handle microphone
handle_microphone() {
    local action="$1"

    if command -v wpctl >/dev/null 2>&1; then
        case $action in
            toggle)
                wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
                local mic_muted=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -o "MUTED" || echo "")
                if [[ -n "$mic_muted" ]]; then
                    notify-send "🎙️ Microphone Muted" -t 1500
                else
                    notify-send "🎙️ Microphone Active" -t 1500
                fi
                ;;
        esac
    fi
}

# Main logic
case "$1" in
    up)
        set_volume "up"
        sleep 0.1  # Small delay for audio system to update
        IFS='|' read -r volume muted <<< "$(get_volume_info)"
        show_notification "$volume" "$muted"
        play_feedback "up"
        update_waybar
        ;;
    down)
        set_volume "down"
        sleep 0.1
        IFS='|' read -r volume muted <<< "$(get_volume_info)"
        show_notification "$volume" "$muted"
        play_feedback "down"
        update_waybar
        ;;
    mute)
        set_volume "mute"
        sleep 0.1
        IFS='|' read -r volume muted <<< "$(get_volume_info)"
        show_notification "$volume" "$muted"
        play_feedback "mute"
        update_waybar
        ;;
    set)
        if [[ -n "$2" ]] && [[ "$2" =~ ^[0-9]+$ ]] && [[ "$2" -ge 0 ]] && [[ "$2" -le 100 ]]; then
            set_volume "set" "$2"
            sleep 0.1
            IFS='|' read -r volume muted <<< "$(get_volume_info)"
            show_notification "$volume" "$muted"
            update_waybar
        else
            echo "Usage: $0 set <volume_percentage>"
            exit 1
        fi
        ;;
    mic)
        handle_microphone "toggle"
        ;;
    status)
        IFS='|' read -r volume muted <<< "$(get_volume_info)"
        if [[ -n "$muted" ]]; then
            echo "Muted"
        else
            echo "$volume%"
        fi
        ;;
    *)
        echo "🔊 Cyberpunk Volume Control"
        echo ""
        echo "Usage: $0 {up|down|mute|set <volume>|mic|status}"
        echo ""
        echo "Commands:"
        echo "  up      - Increase volume by 5%"
        echo "  down    - Decrease volume by 5%"
        echo "  mute    - Toggle audio mute"
        echo "  set X   - Set volume to X% (0-100)"
        echo "  mic     - Toggle microphone mute"
        echo "  status  - Show current volume status"
        exit 1
        ;;
esac
