# 📋 Complete File Manifest - Cyberpunk Medieval Hyprland Setup

This document lists all configuration files, scripts, and templates included in the setup, with their purposes and installation locations.

## 🎯 Core System Files

### Central Configuration
| File | Location | Purpose |
|------|----------|---------|
| `theme-config.json` | `~/.config/hypr-system/core/` | **SINGLE SOURCE OF TRUTH** - All colors, fonts, spacing, effects |
| `keybind-config.json` | `~/.config/hypr-system/core/` | Dynamic keybinding definitions with categories |

### Master Generator
| File | Location | Purpose |
|------|----------|---------|
| `apply-theme.py` | `~/.config/hypr-system/generators/` | Template-based configuration generator |

## 📄 Configuration Templates

### Hyprland Templates
| File | Location | Purpose |
|------|----------|---------|
| `hyprland.template` | `~/.config/hypr-system/templates/` | Main Hyprland configuration |
| `hypr-animations.template` | `~/.config/hypr-system/templates/` | Animation settings and curves |
| `hypr-environment.template` | `~/.config/hypr-system/templates/` | Environment variables |
| `hypr-autostart.template` | `~/.config/hypr-system/templates/` | Startup applications |
| `hypr-rules.template` | `~/.config/hypr-system/templates/` | Window rules and layouts |
| `hypr-monitors.template` | `~/.config/hypr-system/templates/` | Monitor configuration |

### Component Templates
| File | Location | Purpose |
|------|----------|---------|
| `waybar-css.template` | `~/.config/hypr-system/templates/` | Waybar styling and themes |
| `rofi-theme.template` | `~/.config/hypr-system/templates/` | Rofi appearance and colors |
| `dunst.template` | `~/.config/hypr-system/templates/` | Notification styling |
| `kitty.template` | `~/.config/hypr-system/templates/` | Terminal configuration |

## 🎮 EWW Interface System

### Hotkey Display Interface
| File | Location | Purpose |
|------|----------|---------|
| `eww.yuck` | `~/.config/eww/hotkey-display/` | EWW widget definition for hotkey display |
| `style.css` | `~/.config/eww/hotkey-display/` | Cyberpunk styling for hotkey interface |

## 🔨 System Scripts

### Core Management Scripts
| File | Location | Purpose |
|------|----------|---------|
| `hotkey-parser.py` | `~/.config/hypr-system/scripts/` | Dynamic hotkey parsing and JSON generation |
| `hotkey-display.sh` | `~/.config/hypr-system/scripts/` | Hotkey interface launcher (EWW/rofi fallback) |
| `config-menu.sh` | `~/.config/hypr-system/scripts/` | Central configuration menu |
| `theme-manager.sh` | `~/.config/hypr-system/scripts/` | Theme switching and management |

### Media and Device Control
| File | Location | Purpose |
|------|----------|---------|
| `volume-control.sh` | `~/.config/hypr-system/scripts/` | Advanced audio control with notifications |
| `bluetooth-control.sh` | `~/.config/hypr-system/scripts/` | Bluetooth device management interface |
| `wallpaper-cycle.sh` | `~/.config/hypr-system/scripts/` | Dynamic wallpaper management |

### System Utilities
| File | Location | Purpose |
|------|----------|---------|
| `startup-effects.sh` | `~/.config/hypr-system/scripts/` | Startup animations and system initialization |
| `power-menu.sh` | `~/.config/hypr-system/scripts/` | Power management with confirmation dialogs |
| `zerotier-status.sh` | `~/.config/hypr-system/scripts/` | ZeroTier VPN status and control |

## 🚀 Installation and Setup

### Installation Script
| File | Purpose |
|------|---------|
| `install.sh` | Complete automated installation with dependency management |

### Documentation
| File | Purpose |
|------|---------|
| `README.md` | Comprehensive documentation and usage guide |

## 📁 Directory Structure After Installation

```
~/.config/
├── hypr-system/                       # Central management system
│   ├── core/
│   │   ├── theme-config.json          # ⭐ Central theme configuration
│   │   └── keybind-config.json        # ⭐ Dynamic keybindings
│   ├── generators/
│   │   └── apply-theme.py             # ⭐ Master generator
│   ├── templates/
│   │   ├── hyprland.template          # Main Hyprland config template
│   │   ├── hypr-animations.template   # Animation settings template
│   │   ├── hypr-environment.template  # Environment variables template
│   │   ├── hypr-autostart.template    # Autostart applications template
│   │   ├── hypr-rules.template        # Window rules template
│   │   ├── hypr-monitors.template     # Monitor configuration template
│   │   ├── waybar-css.template        # Waybar styling template
│   │   ├── rofi-theme.template        # Rofi theme template
│   │   ├── dunst.template             # Dunst notifications template
│   │   └── kitty.template             # Kitty terminal template
│   ├── scripts/
│   │   ├── hotkey-parser.py           # Dynamic hotkey parsing
│   │   ├── hotkey-display.sh          # Hotkey interface launcher
│   │   ├── config-menu.sh             # Configuration menu
│   │   ├── theme-manager.sh           # Theme management
│   │   ├── volume-control.sh          # Audio control
│   │   ├── bluetooth-control.sh       # Bluetooth management
│   │   ├── wallpaper-cycle.sh         # Wallpaper control
│   │   ├── startup-effects.sh         # System initialization
│   │   ├── power-menu.sh              # Power management
│   │   └── zerotier-status.sh         # VPN status
│   ├── themes/                        # Custom themes
│   ├── wallpapers/                    # Theme wallpapers
│   │   └── cyberpunk-medieval/        # Default theme wallpapers
│   └── backups/                       # Configuration backups
├── hypr/                              # Generated Hyprland configs
│   ├── hyprland.conf                  # Main config (generated)
│   └── configs/                       # Module configs (generated)
│       ├── environment.conf           # Environment variables
│       ├── bindings.conf              # Keybindings (auto-generated)
│       ├── animations.conf            # Animations
│       ├── autostart.conf             # Startup applications
│       ├── rules.conf                 # Window rules
│       └── monitors.conf              # Monitor setup
├── waybar/
│   ├── config.jsonc                   # Waybar configuration (generated)
│   └── style.css                      # Waybar CSS (generated)
├── rofi/
│   └── themes/
│       └── cyberpunk-medieval.rasi    # Rofi theme (generated)
├── dunst/
│   └── dunstrc                        # Dunst config (generated)
├── kitty/
│   └── kitty.conf                     # Kitty config (generated)
└── eww/
    └── hotkey-display/
        ├── eww.yuck                   # EWW widget definition
        └── style.css                  # EWW styling
```

## 🔧 Setup Instructions

### 1. Download All Files
```bash
# Create the directory structure
mkdir -p ~/.config/hypr-system/{core,generators,templates,scripts,themes,wallpapers,backups}
mkdir -p ~/.config/eww/hotkey-display

# Copy each file to its respective location based on the manifest above
```

### 2. Set Permissions
```bash
# Make scripts executable
chmod +x ~/.config/hypr-system/scripts/*.sh
chmod +x ~/.config/hypr-system/generators/*.py
chmod +x install.sh
```

### 3. Install Dependencies
```bash
# Run the installation script
./install.sh

# Or install manually (Arch Linux example):
sudo pacman -S hyprland waybar rofi dunst kitty thunar mpv \
               swww grim slurp wl-clipboard brightnessctl \
               playerctl networkmanager bluez pipewire wireplumber \
               jq python3 git

# Optional but recommended:
yay -S eww-wayland rofi-wayland zerotier-one
```

### 4. Generate Initial Configuration
```bash
# Generate all configurations from templates
cd ~/.config/hypr-system
python3 generators/apply-theme.py
```

### 5. Start Hyprland
```bash
# Log out and select Hyprland from your display manager
# Or start manually:
Hyprland
```

## ⚙️ Key Features of This System

### 🎯 Zero Redundancy
- **Single source of truth**: `theme-config.json` controls all colors and settings
- **Template-based generation**: All config files generated automatically
- **No manual synchronization**: Change once, updates everywhere

### 📱 Dynamic Interface
- **EWW hotkey display**: Modern, searchable interface for shortcuts
- **Auto-generated help**: Hotkeys automatically appear in help system
- **Live configuration**: Changes apply immediately without restarts

### 🎨 Advanced Theming
- **Color reference system**: Use semantic color names instead of hex codes
- **Multi-component theming**: Consistent colors across all applications
- **Easy customization**: Visual editors for common changes

### 🔧 Easy Maintenance
- **Centralized management**: All controls accessible from Waybar menu
- **Automatic backups**: Changes backed up before applying
- **Template system**: Easy to modify and extend configurations

## 🚀 Getting Started Workflow

1. **Install the system** using `install.sh`
2. **Press `Super+H`** to see all available hotkeys
3. **Press `Super+T`** to explore themes
4. **Press `Super+C`** to access configuration menu
5. **Customize** by editing `theme-config.json` and `keybind-config.json`
6. **Apply changes** with the theme generator
7. **Enjoy** your cyberpunk medieval desktop!

## 📚 Important Notes

### File Relationships
- **Templates** → **Generator** → **Final Configs**
- **Central JSONs** → **Template Variables** → **Applied Settings**
- **Keybind Config** → **Hotkey Parser** → **Dynamic Display**

### Modification Workflow
1. Edit central configuration files (`*.json`)
2. Run generator script (`apply-theme.py`)
3. Changes automatically propagate to all components

### Backup Strategy
- Original configs backed up during installation
- Theme changes create automatic backups
- Manual backups available in `backups/` directory

This system provides a complete, maintainable Hyprland setup with zero redundancy and maximum customization potential! 🗡️✨
