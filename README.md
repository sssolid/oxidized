# 🗡️ Cyberpunk Medieval Hyprland Setup 🤖

A comprehensive, dynamic Hyprland configuration system with cyberpunk aesthetics and medieval touches. Features a centralized configuration system, zero redundancy, and beautiful interfaces.

![Cyberpunk Medieval Theme](https://img.shields.io/badge/Theme-Cyberpunk%20Medieval-00ffff?style=for-the-badge&logo=linux)
![Hyprland](https://img.shields.io/badge/Hyprland-Wayland%20Compositor-ffd700?style=for-the-badge)
![Dynamic Config](https://img.shields.io/badge/Dynamic-Configuration-8a2be2?style=for-the-badge)

## ✨ Features

### 🎯 **Core Philosophy: Single Source of Truth**
- **Zero redundancy** - Change colors once, updates everywhere
- **Template-based generation** - All configs generated from central JSON
- **Dynamic hotkey system** - Add keybind once, appears in help automatically
- **Modular architecture** - Easy to maintain and extend

### 🎨 **Dynamic Theming System**
- **Central theme configuration** (`theme-config.json`)
- **Color reference system** (`cyberpunk.neon_cyan`, `medieval.royal_gold`)
- **Real-time theme switching** with live preview
- **Multiple built-in themes** (Neo Tokyo, Dark Ages, Matrix Green)
- **Custom theme creation** with visual editor

### ⌨️ **Intelligent Hotkey Management**
- **Dynamic hotkey display** using EWW interface
- **Categorized shortcuts** (Applications, Windows, Workspaces, etc.)
- **Auto-generated help** - no manual updates needed
- **Search functionality** in hotkey display
- **Visual key representations** (⊞ for Super, ⇧ for Shift)

### 🎮 **Advanced Interface System**
- **EWW-based widgets** for modern, responsive interfaces
- **Waybar integration** with dynamic modules
- **Rofi theming** with cyberpunk aesthetics
- **Beautiful notifications** via Dunst
- **Terminal integration** with Kitty

### 🔧 **Easy Configuration Management**
- **Configuration menu** in Waybar (gear icon)
- **Visual editors** for common tasks
- **One-click theme switching**
- **Automatic backup system**
- **Real-time preview** for changes

## 🚀 Quick Start

### Prerequisites
```bash
# Required packages (Arch Linux example)
sudo pacman -S hyprland waybar rofi dunst kitty thunar mpv \
               swww grim slurp wl-clipboard brightnessctl \
               playerctl networkmanager bluez pipewire wireplumber \
               jq python3 git

# AUR packages (optional but recommended)
yay -S eww-wayland rofi-wayland zerotier-one
```

### Installation
```bash
# Download and run installer
curl -sSL https://raw.githubusercontent.com/sssolid/oxidized/master/install.sh | bash

# Or manually:
git clone https://github.com/sssolid/oxidized.git
cd oxidized
chmod +x install.sh
./install.sh
```

### First Steps
1. **Log out and select Hyprland** from your display manager
2. **Press `Super+H`** to view all hotkeys
3. **Press `Super+T`** to open theme manager
4. **Press `Super+C`** to access configuration menu
5. **Add wallpapers** to `~/.config/hypr-system/wallpapers/cyberpunk-medieval/`

## 📁 Directory Structure

```
~/.config/hypr-system/                 # Central management system
├── core/
│   ├── theme-config.json              # 🎨 SINGLE SOURCE OF TRUTH
│   └── keybind-config.json            # ⌨️ Dynamic keybinding definitions
├── generators/
│   └── apply-theme.py                 # 🔧 Master configuration generator
├── templates/                         # 📄 Configuration templates
│   ├── hyprland.template
│   ├── waybar-css.template
│   ├── rofi-theme.template
│   └── dunst.template
├── scripts/                           # 🔨 System scripts
│   ├── hotkey-display.sh              # Dynamic hotkey interface
│   ├── theme-manager.sh               # Theme management
│   ├── config-menu.sh                 # Configuration hub
│   ├── volume-control.sh              # Advanced audio control
│   ├── wallpaper-cycle.sh             # Wallpaper management
│   └── bluetooth-control.sh           # Bluetooth interface
├── themes/                            # 🎭 Custom themes
├── wallpapers/                        # 🖼️ Theme wallpapers
└── backups/                           # 💾 Configuration backups
```

## ⌨️ Default Hotkeys

### 🚀 Applications
| Hotkey | Action |
|--------|--------|
| `Super + Enter` | Terminal (Kitty) |
| `Super + Space` | App Launcher (Rofi) |
| `Super + E` | File Manager (Thunar) |
| `Super + Q` | Close Window |
| `Super + M` | Exit Hyprland |

### 🪟 Window Management
| Hotkey | Action |
|--------|--------|
| `Super + ←/→/↑/↓` | Focus Window |
| `Super + Shift + ←/→/↑/↓` | Move Window |
| `Super + Ctrl + ←/→/↑/↓` | Resize Window |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle Floating |
| `Super + J` | Toggle Split |

### 🏰 Workspaces (Medieval Names)
| Hotkey | Workspace | Name |
|--------|-----------|------|
| `Super + 1` | 1 | 🏰 The Keep |
| `Super + 2` | 2 | ⚒️ The Forge |
| `Super + 3` | 3 | 📚 The Library |
| `Super + 4` | 4 | 🍺 The Tavern |
| `Super + 5` | 5 | 🏪 The Market |

### 🔧 System Controls
| Hotkey | Action |
|--------|--------|
| `Super + H` | **Show All Hotkeys** |
| `Super + T` | **Theme Manager** |
| `Super + C` | **Configuration Menu** |
| `Super + W` | Cycle Wallpaper |
| `Super + L` | Lock Screen |
| `Super + B` | Bluetooth Control |

## 🎨 Theme System

### Built-in Themes
- **Cyberpunk Medieval** (default) - Cyan/gold with medieval touches
- **Neo Tokyo** - Bright neon pink and cyan
- **Dark Ages** - Muted medieval colors
- **Matrix Green** - Classic green terminal theme

### Creating Custom Themes
1. **Use Theme Manager**: `Super + T` → "Create Custom Theme"
2. **Edit JSON directly**: Modify `~/.config/hypr-system/core/theme-config.json`
3. **Apply changes**: Run `~/.config/hypr-system/generators/apply-theme.py`

### Color Reference System
Instead of repeating hex codes, use references:
```json
{
  "colors": {
    "cyberpunk": {
      "neon_cyan": "#00ffff"
    },
    "semantic": {
      "border_active": "cyberpunk.neon_cyan"  // References color above
    }
  }
}
```

## 🔧 Configuration Guide

### Central Theme Configuration
Edit `~/.config/hypr-system/core/theme-config.json`:

```json
{
  "colors": {
    "primary": {
      "bg_primary": "#0d1117",    // Main background
      "bg_secondary": "#161b22"   // Secondary background
    },
    "cyberpunk": {
      "neon_cyan": "#00ffff",     // Primary accent
      "neon_pink": "#ff006e"      // Secondary accent
    }
  },
  "spacing": {
    "gaps_inner": 8,              // Window gaps
    "gaps_outer": 16,             // Screen gaps
    "border_width": 3,            // Window borders
    "rounding": 12                // Corner radius
  }
}
```

### Adding Custom Hotkeys
Edit `~/.config/hypr-system/core/keybind-config.json`:

```json
{
  "categories": {
    "custom": {
      "name": "🔥 Custom Shortcuts",
      "icon": "🔥",
      "bindings": {
        "SUPER, G": {
          "command": "google-chrome",
          "description": "Open Chrome Browser"
        }
      }
    }
  }
}
```

### Regenerating Configuration
After making changes:
```bash
# Regenerate all configs from templates
~/.config/hypr-system/generators/apply-theme.py

# Or use the configuration menu
# Super + C → "Apply Changes"
```

## 🎮 Interface System

### EWW Hotkey Display
Modern, searchable hotkey interface:
- **Dynamic content** - automatically reflects current keybindings
- **Search functionality** - find hotkeys quickly
- **Visual key representations** - ⊞ ⇧ ⌃ symbols
- **Copy to clipboard** - click 📋 to copy hotkey

### Waybar Configuration Menu
Click the ⚙️ icon in Waybar for quick access to:
- Theme Editor
- Keybinding Editor
- Wallpaper Manager
- System Settings
- Configuration Files

### Rofi Integration
All menus use consistent cyberpunk theming:
- Application launcher (`Super + Space`)
- Configuration menus
- Theme selection
- Device management

## 🖼️ Wallpaper System

### Adding Wallpapers
```bash
# Add wallpapers to theme directory
cp your-wallpaper.jpg ~/.config/hypr-system/wallpapers/cyberpunk-medieval/

# Use wallpaper manager
Super + W  # Cycle through wallpapers
```

### Wallpaper Features
- **Theme-based organization** - different wallpapers per theme
- **Smooth transitions** - configurable transition effects
- **Time-based switching** - different wallpapers for different times
- **Random selection** - surprise yourself

## 🔊 Audio & Media Control

### Volume Control Features
- **Visual notifications** - progress bars and volume indicators
- **Multiple backends** - WirePlumber, PulseAudio, ALSA support
- **Sound feedback** - audio cues for volume changes
- **Microphone control** - toggle mic with notifications

### Media Keys
All standard media keys are supported:
- Volume up/down/mute
- Play/pause/next/previous
- Brightness control

## 🔵 Bluetooth Management

### Bluetooth Features
- **Device discovery** - scan for nearby devices
- **Easy pairing** - one-click pairing process
- **Connection management** - connect/disconnect devices
- **Battery monitoring** - show device battery levels
- **Audio profiles** - automatic profile switching

## 📊 System Monitoring

### Waybar Modules
- **System resources** - CPU, memory, disk usage
- **Network status** - WiFi signal, VPN connections
- **Bluetooth status** - connected devices
- **Audio levels** - current volume and output device
- **Battery status** - charge level and time remaining
- **ZeroTier VPN** - connection status

## 🔧 Advanced Configuration

### Template System
All configuration files are generated from templates in `~/.config/hypr-system/templates/`:

- `hyprland.template` - Main Hyprland configuration
- `waybar-css.template` - Waybar styling
- `rofi-theme.template` - Rofi appearance
- `dunst.template` - Notification styling
- `kitty.template` - Terminal configuration

### Adding New Templates
1. Create template file with placeholder variables: `${variable_name}`
2. Add variable definitions to theme generator
3. Register template in `apply-theme.py`

### Backup System
Automatic backups are created:
- **Before theme changes** - previous theme saved
- **During installation** - existing configs backed up
- **On shutdown** - session state preserved

## 🚨 Troubleshooting

### Common Issues

#### Theme not applying
```bash
# Check theme generator
~/.config/hypr-system/generators/apply-theme.py

# Check for JSON syntax errors
jq . ~/.config/hypr-system/core/theme-config.json
```

#### Hotkeys not working
```bash
# Regenerate keybindings
~/.config/hypr-system/generators/apply-theme.py

# Check Hyprland config
hyprctl reload
```

#### EWW widgets not showing
```bash
# Restart EWW daemon
eww kill && eww daemon

# Check EWW configuration
eww ping
```

#### Waybar not updating
```bash
# Restart Waybar
pkill waybar && waybar &

# Check Waybar logs
journalctl -u waybar --since "1 hour ago"
```

### Getting Help
1. **Check logs**: `journalctl -f` while reproducing issue
2. **Verify dependencies**: Ensure all required packages are installed
3. **Reset configuration**: Use backup files in `~/.config/hypr-system/backups/`
4. **Community support**: GitHub Issues, Discord, Reddit r/hyprland

## 🎯 Tips & Tricks

### Performance Optimization
- **Reduce animations** - Edit `effects.animations.enabled` in theme config
- **Lower blur passes** - Reduce `effects.blur.passes` value
- **Disable shadows** - Set `effects.shadow.enabled` to false

### Customization Ideas
- **Add more workspaces** - Extend workspace names and icons in theme config
- **Custom wallpaper scripts** - Create time/weather-based wallpaper changes
- **Integration scripts** - Connect with smart home systems
- **Custom widgets** - Add EWW widgets for system monitoring

### Workflow Enhancements
- **Use special workspaces** - `Super + S` for floating workspace
- **Master-stack layout** - Switch layouts with `Super + J`
- **Floating windows** - Use `Super + V` for specific applications
- **Multi-monitor setup** - Configure in `configs/monitors.conf`

## 🔄 Updates & Maintenance

### Updating the System
```bash
# Check for updates
cd ~/.config/hypr-system
git pull

# Update dependencies
sudo pacman -Syu  # Arch Linux
./install.sh update
```

### Maintenance Tasks
- **Clean old backups** - Remove old files from `backups/` directory
- **Update wallpapers** - Add new wallpapers for variety
- **Review themes** - Try different built-in themes
- **Optimize performance** - Adjust settings based on hardware

## 🤝 Contributing

### Ways to Contribute
- **Report bugs** - Create detailed issue reports
- **Add themes** - Design new color schemes
- **Improve templates** - Enhance configuration templates
- **Write documentation** - Help others understand the system
- **Create widgets** - Design new EWW components

### Development Setup
```bash
# Fork the repository
git clone https://github.com/sssolid/oxidized.git
cd oxidized

# Create feature branch
git checkout -b feature/your-feature

# Make changes and test
./install.sh

# Submit pull request
```

## 📜 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

- **Hyprland** - Amazing Wayland compositor
- **Waybar** - Highly customizable status bar
- **EWW** - ElKowar's wacky widgets
- **Rofi** - Window switcher and application launcher
- **Community** - All the amazing contributors and users

---

**🗡️ May your desktop be ever oxidized and your windows ever managed! 🤖**

For more information, visit: [GitHub Repository](https://github.com/sssolid/oxidized)
