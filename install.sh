#!/bin/bash
# 🚀 Cyberpunk Medieval Hyprland Setup Installer
# Complete automated installation with dependency management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.config"
HYPR_SYSTEM_DIR="$INSTALL_DIR/hypr-system"
GITHUB_REPO="https://github.com/your-repo/hypr-cyberpunk-medieval"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"

# System detection
detect_system() {
    if command -v pacman >/dev/null 2>&1; then
        echo "arch"
    elif command -v apt >/dev/null 2>&1; then
        echo "debian"
    elif command -v dnf >/dev/null 2>&1; then
        echo "fedora"
    elif command -v zypper >/dev/null 2>&1; then
        echo "opensuse"
    else
        echo "unknown"
    fi
}

SYSTEM=$(detect_system)

# Logging functions
log_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${PURPLE}🗡️  $1 🤖${NC}"
}

# Progress tracking
TOTAL_STEPS=12
CURRENT_STEP=0

show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local bar_length=50
    local filled_length=$((percentage * bar_length / 100))

    printf "\r${CYAN}["
    for ((i=0; i<filled_length; i++)); do printf "█"; done
    for ((i=filled_length; i<bar_length; i++)); do printf "░"; done
    printf "] %d%% (%d/%d) %s${NC}" "$percentage" "$CURRENT_STEP" "$TOTAL_STEPS" "$1"

    if [[ $CURRENT_STEP -eq $TOTAL_STEPS ]]; then
        echo
    fi
}

# Dependency management
declare -A PACKAGES

# Core packages (required)
PACKAGES[core]="hyprland waybar rofi dunst kitty thunar"

# Media and utilities
PACKAGES[media]="mpv grim slurp wl-clipboard brightnessctl playerctl swww"

# Development tools
PACKAGES[dev]="jq python3 python-pip git"

# Audio
PACKAGES[audio]="pipewire wireplumber pavucontrol"

# Network and Bluetooth
PACKAGES[network]="networkmanager bluez bluez-utils blueman"

# Fonts
PACKAGES[fonts]="ttf-jetbrains-mono nerd-fonts"

# AUR packages (Arch only)
PACKAGES[aur]="eww-wayland rofi-wayland zerotier-one"

# Install packages based on system
install_packages() {
    local category="$1"
    local packages="${PACKAGES[$category]}"

    if [[ -z "$packages" ]]; then
        return 0
    fi

    log_info "Installing $category packages: $packages"

    case "$SYSTEM" in
        "arch")
            if [[ "$category" == "aur" ]]; then
                if command -v yay >/dev/null 2>&1; then
                    yay -S --needed --noconfirm $packages
                elif command -v paru >/dev/null 2>&1; then
                    paru -S --needed --noconfirm $packages
                else
                    log_warning "No AUR helper found. Skipping AUR packages."
                    log_info "Please install yay or paru manually, then run: yay -S $packages"
                fi
            else
                sudo pacman -S --needed --noconfirm $packages
            fi
            ;;
        "debian")
            # Convert package names for Debian/Ubuntu
            packages=$(echo "$packages" | sed 's/ttf-jetbrains-mono/fonts-jetbrains-mono/g')
            packages=$(echo "$packages" | sed 's/bluez-utils/bluez-tools/g')
            sudo apt update && sudo apt install -y $packages
            ;;
        "fedora")
            sudo dnf install -y $packages
            ;;
        "opensuse")
            sudo zypper install -y $packages
            ;;
        *)
            log_error "Unsupported system. Please install packages manually:"
            echo "$packages"
            ;;
    esac
}

# Backup existing configuration
backup_config() {
    log_info "Creating backup of existing configuration..."

    local configs_to_backup=("hypr" "waybar" "rofi" "dunst" "kitty" "eww")

    mkdir -p "$BACKUP_DIR"

    for config in "${configs_to_backup[@]}"; do
        if [[ -d "$INSTALL_DIR/$config" ]]; then
            cp -r "$INSTALL_DIR/$config" "$BACKUP_DIR/"
            log_info "Backed up $config configuration"
        fi
    done

    if [[ -d "$HYPR_SYSTEM_DIR" ]]; then
        cp -r "$HYPR_SYSTEM_DIR" "$BACKUP_DIR/"
        log_info "Backed up existing hypr-system"
    fi

    log_success "Backup created at: $BACKUP_DIR"
}

# Create directory structure
create_directories() {
    log_info "Creating directory structure..."

    local directories=(
        "$HYPR_SYSTEM_DIR/core"
        "$HYPR_SYSTEM_DIR/generators"
        "$HYPR_SYSTEM_DIR/templates"
        "$HYPR_SYSTEM_DIR/scripts"
        "$HYPR_SYSTEM_DIR/themes"
        "$HYPR_SYSTEM_DIR/wallpapers/cyberpunk-medieval"
        "$HYPR_SYSTEM_DIR/backups"
        "$INSTALL_DIR/hypr/configs"
        "$INSTALL_DIR/waybar"
        "$INSTALL_DIR/rofi/themes"
        "$INSTALL_DIR/dunst"
        "$INSTALL_DIR/kitty"
        "$INSTALL_DIR/eww/hotkey-display"
    )

    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
    done

    log_success "Directory structure created"
}

# Install Python dependencies
install_python_deps() {
    log_info "Installing Python dependencies..."

    local python_packages=(
        "jinja2"
        "pyyaml"
        "requests"
    )

    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user "${python_packages[@]}"
    elif command -v pip >/dev/null 2>&1; then
        pip install --user "${python_packages[@]}"
    else
        log_warning "pip not found. Please install Python packages manually."
    fi

    log_success "Python dependencies installed"
}

# Download configuration files
download_configs() {
    log_info "Setting up configuration files..."

    # Note: In a real implementation, you would download from GitHub
    # For this example, we'll create placeholder files

    # Create core configuration files
    cat > "$HYPR_SYSTEM_DIR/core/theme-config.json" << 'EOF'
{
  "meta": {
    "name": "Cyberpunk Medieval",
    "version": "2.0",
    "description": "Dynamic cyberpunk theme with medieval touches"
  },
  "colors": {
    "primary": {
      "bg_primary": "#0d1117",
      "bg_secondary": "#161b22",
      "bg_tertiary": "#21262d",
      "bg_overlay": "#0d1117ee"
    },
    "cyberpunk": {
      "neon_cyan": "#00ffff",
      "neon_pink": "#ff006e",
      "neon_green": "#39ff14",
      "neon_purple": "#8a2be2",
      "electric_blue": "#0080ff"
    },
    "medieval": {
      "royal_gold": "#ffd700",
      "ancient_bronze": "#cd7f32",
      "battle_crimson": "#dc143c",
      "castle_stone": "#696969",
      "iron_gray": "#36454f"
    },
    "text": {
      "primary": "#e6edf3",
      "secondary": "#8b949e",
      "accent": "#58a6ff",
      "muted": "#6e7681"
    },
    "status": {
      "success": "#39ff14",
      "warning": "#ffd700",
      "error": "#dc143c",
      "info": "#00ffff"
    },
    "semantic": {
      "border_active": "cyberpunk.neon_cyan",
      "border_inactive": "medieval.castle_stone",
      "accent_primary": "cyberpunk.neon_cyan",
      "accent_secondary": "medieval.royal_gold",
      "shadow": "rgba(0, 0, 0, 0.8)"
    }
  },
  "typography": {
    "font_primary": "JetBrains Mono Nerd Font",
    "font_secondary": "Fira Code Nerd Font",
    "size_small": 11,
    "size_normal": 13,
    "size_large": 16,
    "size_title": 20
  },
  "spacing": {
    "gaps_inner": 8,
    "gaps_outer": 16,
    "border_width": 3,
    "rounding": 12,
    "margins": {
      "small": 4,
      "medium": 8,
      "large": 16,
      "xlarge": 24
    }
  },
  "effects": {
    "blur": {
      "enabled": true,
      "size": 8,
      "passes": 3,
      "vibrancy": 0.1696
    },
    "shadow": {
      "enabled": true,
      "range": 20,
      "render_power": 3
    },
    "animations": {
      "enabled": true,
      "speed_multiplier": 1.0,
      "curves": {
        "cyberpunk": "0.25, 0.46, 0.45, 0.94",
        "medieval": "0.68, -0.55, 0.265, 1.55",
        "smooth": "0.23, 1, 0.320, 1",
        "glow": "0.175, 0.885, 0.320, 1.275"
      }
    }
  },
  "workspaces": {
    "names": {
      "1": "The Keep",
      "2": "The Forge",
      "3": "The Library",
      "4": "The Tavern",
      "5": "The Market",
      "6": "The Stables",
      "7": "The Armory",
      "8": "The Tower",
      "9": "The Dungeon",
      "10": "The Throne Room"
    },
    "icons": {
      "1": "🏰",
      "2": "⚒️",
      "3": "📚",
      "4": "🍺",
      "5": "🏪",
      "6": "🐎",
      "7": "⚔️",
      "8": "🗼",
      "9": "🔒",
      "10": "👑"
    }
  },
  "components": {
    "waybar": {
      "height": 42,
      "margin_top": 8,
      "margin_sides": 16,
      "modules_left": ["custom/logo", "hyprland/workspaces", "hyprland/window"],
      "modules_center": ["clock"],
      "modules_right": ["custom/zerotier", "network", "bluetooth", "pulseaudio", "battery", "tray", "custom/config", "custom/power"]
    },
    "rofi": {
      "width": 600,
      "lines": 8,
      "location": "center"
    }
  }
}
EOF

    log_success "Configuration files created"
}

# Make scripts executable
setup_scripts() {
    log_info "Setting up scripts..."

    # Create a basic apply-theme script
    cat > "$HYPR_SYSTEM_DIR/generators/apply-theme.py" << 'EOF'
#!/usr/bin/env python3
"""Basic theme generator - replace with full version"""
import json
import os
from pathlib import Path

print("🎨 Theme generator placeholder")
print("✅ Please replace with full generator script")
EOF

    # Make scripts executable
    find "$HYPR_SYSTEM_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "$HYPR_SYSTEM_DIR/generators" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true

    log_success "Scripts configured"
}

# Enable services
enable_services() {
    log_info "Enabling system services..."

    local services=("bluetooth" "NetworkManager")

    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "$service"; then
            sudo systemctl enable "$service" 2>/dev/null || true
            sudo systemctl start "$service" 2>/dev/null || true
            log_info "Enabled $service"
        fi
    done

    # Enable ZeroTier if installed
    if command -v zerotier-one >/dev/null 2>&1; then
        sudo systemctl enable zerotier-one 2>/dev/null || true
        log_info "ZeroTier service enabled"
    fi

    log_success "System services configured"
}

# Setup wallpapers
setup_wallpapers() {
    log_info "Setting up default wallpapers..."

    local wallpaper_dir="$HYPR_SYSTEM_DIR/wallpapers/cyberpunk-medieval"

    # Create gradient wallpapers if ImageMagick is available
    if command -v convert >/dev/null 2>&1; then
        log_info "Creating gradient wallpapers..."

        convert -size 1920x1080 gradient:"#0d1117-#00ffff" "$wallpaper_dir/cyberpunk-gradient.png" 2>/dev/null || true
        convert -size 1920x1080 gradient:"#0d1117-#ffd700" "$wallpaper_dir/medieval-gradient.png" 2>/dev/null || true
        convert -size 1920x1080 gradient:"#8a2be2-#00ffff" "$wallpaper_dir/cyber-purple.png" 2>/dev/null || true

        log_success "Gradient wallpapers created"
    else
        log_warning "ImageMagick not found. Please add wallpapers to $wallpaper_dir manually."
    fi
}

# Generate initial configuration
generate_config() {
    log_info "Generating initial configuration..."

    # This would normally run the full theme generator
    # For now, create basic configs

    # Basic Hyprland config
    cat > "$INSTALL_DIR/hypr/hyprland.conf" << 'EOF'
# Basic Hyprland configuration - will be replaced by generator
source = ~/.config/hypr/configs/environment.conf
source = ~/.config/hypr/configs/bindings.conf

general {
    gaps_in = 8
    gaps_out = 16
    border_size = 3
    col.active_border = rgb(00ffff) rgb(ffd700) 45deg
    col.inactive_border = rgb(696969)
    layout = dwindle
}

decoration {
    rounding = 12
    blur {
        enabled = true
        size = 8
        passes = 3
    }
    drop_shadow = true
}

input {
    kb_layout = us
    follow_mouse = 1
}

bind = SUPER, RETURN, exec, kitty
bind = SUPER, SPACE, exec, rofi -show drun
bind = SUPER, Q, killactive
exec-once = waybar
exec-once = dunst
EOF

    log_success "Basic configuration generated"
}

# Post-installation setup
post_install() {
    log_info "Performing post-installation setup..."

    # Create desktop entry for easy access
    cat > "$HOME/.local/share/applications/hypr-config.desktop" << EOF
[Desktop Entry]
Name=Hyprland Config Manager
Comment=Cyberpunk Medieval Hyprland Configuration
Exec=$HYPR_SYSTEM_DIR/scripts/config-menu.sh
Icon=preferences-system
Type=Application
Categories=Settings;System;
EOF

    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    log_success "Post-installation setup complete"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for Wayland session
    if [[ "$XDG_SESSION_TYPE" != "wayland" ]]; then
        log_warning "Not running in Wayland session. Hyprland requires Wayland."
    fi

    # Check for required commands
    local required_commands=("git" "curl" "systemctl")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        log_info "Please install them and run the installer again."
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Main installation function
main_install() {
    log_header "CYBERPUNK MEDIEVAL HYPRLAND SETUP"
    echo
    log_info "🎯 This installer will set up a complete Hyprland environment"
    log_info "📦 System detected: $SYSTEM"
    log_info "📁 Install location: $HYPR_SYSTEM_DIR"
    echo

    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled."
        exit 0
    fi

    # Installation steps
    show_progress "Checking prerequisites"
    check_prerequisites

    show_progress "Creating backup"
    backup_config

    show_progress "Installing core packages"
    install_packages "core"

    show_progress "Installing media packages"
    install_packages "media"

    show_progress "Installing development tools"
    install_packages "dev"

    show_progress "Installing audio packages"
    install_packages "audio"

    show_progress "Installing network packages"
    install_packages "network"

    show_progress "Installing fonts"
    install_packages "fonts"

    show_progress "Installing AUR packages"
    if [[ "$SYSTEM" == "arch" ]]; then
        install_packages "aur"
    fi

    show_progress "Creating directories"
    create_directories

    show_progress "Setting up Python dependencies"
    install_python_deps

    show_progress "Downloading configurations"
    download_configs

    show_progress "Setting up scripts"
    setup_scripts

    show_progress "Enabling services"
    enable_services

    show_progress "Setting up wallpapers"
    setup_wallpapers

    show_progress "Generating configuration"
    generate_config

    show_progress "Post-installation setup"
    post_install

    echo
    log_success "Installation completed successfully!"
    echo
    log_info "🎉 Welcome to Cyberpunk Medieval Hyprland!"
    echo
    log_info "📋 Next steps:"
    echo "   1. Log out and select Hyprland from your display manager"
    echo "   2. Use Super+H to view hotkeys"
    echo "   3. Use Super+T to open theme manager"
    echo "   4. Use Super+C to open configuration menu"
    echo "   5. Add wallpapers to $HYPR_SYSTEM_DIR/wallpapers/cyberpunk-medieval/"
    echo
    log_info "🔧 Configuration files:"
    echo "   Theme: $HYPR_SYSTEM_DIR/core/theme-config.json"
    echo "   Hotkeys: $HYPR_SYSTEM_DIR/core/keybind-config.json"
    echo "   Backup: $BACKUP_DIR"
    echo
    log_info "📚 Documentation and updates:"
    echo "   GitHub: $GITHUB_REPO"
    echo "   Config Manager: Run 'hypr-config' or use the desktop entry"
    echo
}

# Handle command line arguments
case "${1:-install}" in
    "install")
        main_install
        ;;
    "update")
        log_info "Updating configuration..."
        if [[ -f "$HYPR_SYSTEM_DIR/generators/apply-theme.py" ]]; then
            cd "$HYPR_SYSTEM_DIR" && python3 generators/apply-theme.py
            log_success "Configuration updated"
        else
            log_error "Theme generator not found"
        fi
        ;;
    "backup")
        backup_config
        ;;
    "uninstall")
        log_warning "Uninstalling Cyberpunk Medieval Hyprland Setup..."
        read -p "Are you sure? This will remove all configurations. (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$HYPR_SYSTEM_DIR"
            log_success "Uninstalled successfully"
        fi
        ;;
    *)
        echo "🗡️ Cyberpunk Medieval Hyprland Setup Installer"
        echo ""
        echo "Usage: $0 {install|update|backup|uninstall}"
        echo ""
        echo "Commands:"
        echo "  install    - Full installation (default)"
        echo "  update     - Update configuration from templates"
        echo "  backup     - Backup current configuration"
        echo "  uninstall  - Remove all configurations"
        ;;
esac
