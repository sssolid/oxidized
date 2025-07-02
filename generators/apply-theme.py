#!/usr/bin/env python3
"""
🎨 Master Theme Generator (Template-Based)
Generates all component configurations from central theme config using templates
"""

import json
import os
import sys
from pathlib import Path
from string import Template
import subprocess
import re

class ThemeGenerator:
    def __init__(self):
        self.config_dir = Path.home() / ".config" / "hypr-system"
        self.template_dir = self.config_dir / "templates"
        self.output_dir = Path.home() / ".config"

        self.theme_config = self.load_theme_config()
        self.keybind_config = self.load_keybind_config()

    def load_theme_config(self):
        """Load central theme configuration"""
        try:
            with open(self.config_dir / "core" / "theme-config.json") as f:
                return json.load(f)
        except FileNotFoundError:
            print("❌ Theme config not found. Please ensure theme-config.json exists.")
            sys.exit(1)

    def load_keybind_config(self):
        """Load keybinding configuration"""
        try:
            with open(self.config_dir / "core" / "keybind-config.json") as f:
                return json.load(f)
        except FileNotFoundError:
            print("❌ Keybind config not found. Please ensure keybind-config.json exists.")
            sys.exit(1)

    def resolve_color(self, color_ref):
        """Resolve color references like 'cyberpunk.neon_cyan' to actual hex values"""
        if color_ref.startswith('#') or color_ref.startswith('rgba'):
            return color_ref

        parts = color_ref.split('.')
        if len(parts) == 2:
            category, color = parts
            if category in self.theme_config['colors'] and color in self.theme_config['colors'][category]:
                return self.theme_config['colors'][category][color]
        return color_ref

    def get_resolved_colors(self):
        """Get all colors with references resolved"""
        colors = {}
        for category, color_group in self.theme_config['colors'].items():
            colors[category] = {}
            for name, value in color_group.items():
                colors[category][name] = self.resolve_color(value)
        return colors

    def get_template_variables(self):
        """Get all template variables for substitution"""
        colors = self.get_resolved_colors()
        theme = self.theme_config

        # Flatten colors for easy template access
        vars_dict = {}
        for category, color_group in colors.items():
            for name, value in color_group.items():
                vars_dict[f"{category}_{name}"] = value

        # Add theme settings
        vars_dict.update({
            'font_primary': theme['typography']['font_primary'],
            'font_secondary': theme['typography']['font_secondary'],
            'font_size_small': theme['typography']['size_small'],
            'font_size_normal': theme['typography']['size_normal'],
            'font_size_large': theme['typography']['size_large'],
            'font_size_title': theme['typography']['size_title'],

            'gaps_inner': theme['spacing']['gaps_inner'],
            'gaps_outer': theme['spacing']['gaps_outer'],
            'border_width': theme['spacing']['border_width'],
            'rounding': theme['spacing']['rounding'],
            'margin_small': theme['spacing']['margins']['small'],
            'margin_medium': theme['spacing']['margins']['medium'],
            'margin_large': theme['spacing']['margins']['large'],
            'margin_xlarge': theme['spacing']['margins']['xlarge'],

            'blur_enabled': str(theme['effects']['blur']['enabled']).lower(),
            'blur_size': theme['effects']['blur']['size'],
            'blur_passes': theme['effects']['blur']['passes'],
            'blur_vibrancy': theme['effects']['blur']['vibrancy'],

            'shadow_enabled': str(theme['effects']['shadow']['enabled']).lower(),
            'shadow_range': theme['effects']['shadow']['range'],
            'shadow_render_power': theme['effects']['shadow']['render_power'],

            'anim_enabled': str(theme['effects']['animations']['enabled']).lower(),
            'curve_cyberpunk': theme['effects']['animations']['curves']['cyberpunk'],
            'curve_medieval': theme['effects']['animations']['curves']['medieval'],
            'curve_smooth': theme['effects']['animations']['curves']['smooth'],
            'curve_glow': theme['effects']['animations']['curves']['glow'],

            'waybar_height': theme['components']['waybar']['height'],
            'waybar_margin_top': theme['components']['waybar']['margin_top'],
            'waybar_margin_sides': theme['components']['waybar']['margin_sides'],

            'rofi_width': theme['components']['rofi']['width'],
            'rofi_lines': theme['components']['rofi']['lines'],
        })

        return vars_dict

    def load_template(self, template_name):
        """Load a template file"""
        template_path = self.template_dir / f"{template_name}.template"
        if not template_path.exists():
            print(f"⚠️ Template {template_name} not found at {template_path}")
            return None

        with open(template_path, 'r') as f:
            return Template(f.read())

    def generate_from_template(self, template_name, output_path, additional_vars=None):
        """Generate a configuration file from a template"""
        template = self.load_template(template_name)
        if not template:
            return False

        # Get base variables
        vars_dict = self.get_template_variables()

        # Add any additional variables
        if additional_vars:
            vars_dict.update(additional_vars)

        try:
            content = template.substitute(vars_dict)

            # Ensure output directory exists
            output_path.parent.mkdir(parents=True, exist_ok=True)

            # Write the file
            with open(output_path, 'w') as f:
                f.write(content)

            return True
        except KeyError as e:
            print(f"❌ Template variable missing: {e}")
            return False
        except Exception as e:
            print(f"❌ Error generating {template_name}: {e}")
            return False

    def generate_keybindings(self):
        """Generate keybindings configuration"""
        print("⌨️ Generating keybindings...")

        bindings_content = "# 🗡️ Generated Keybindings - DO NOT EDIT MANUALLY\n\n"

        for category_name, category in self.keybind_config['categories'].items():
            bindings_content += f"# {category['name']}\n"
            for key_combo, binding in category['bindings'].items():
                bind_type = binding.get('type', 'bind')
                bindings_content += f"{bind_type} = {key_combo}, {binding['command']}\n"
            bindings_content += "\n"

        output_path = self.output_dir / "hypr" / "configs" / "bindings.conf"
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, 'w') as f:
            f.write(bindings_content)

    def generate_waybar_config(self):
        """Generate Waybar JSON configuration"""
        print("📊 Generating Waybar config...")

        waybar_config = self.theme_config['components']['waybar']
        workspaces = self.theme_config['workspaces']

        # Build the configuration
        config = {
            "layer": "top",
            "position": "top",
            "height": waybar_config['height'],
            "spacing": self.theme_config['spacing']['margins']['medium'],
            "margin-top": waybar_config['margin_top'],
            "margin-left": waybar_config['margin_sides'],
            "margin-right": waybar_config['margin_sides'],
            "modules-left": waybar_config['modules_left'],
            "modules-center": waybar_config['modules_center'],
            "modules-right": waybar_config['modules_right'],

            # Module configurations
            "custom/logo": {
                "format": "⚔️",
                "tooltip": False,
                "on-click": "rofi -show drun"
            },
            "hyprland/workspaces": {
                "format": "{icon}",
                "format-icons": workspaces['icons'],
                "persistent_workspaces": {str(i): [] for i in range(1, 6)},
                "on-click": "activate"
            },
            "hyprland/window": {
                "format": "{}",
                "max-length": 50,
                "tooltip": False
            },
            "clock": {
                "format": "{:%H:%M 🕐 %a %d %b}",
                "format-alt": "{:%Y-%m-%d %H:%M:%S}",
                "tooltip-format": "<big>{:%Y %B}</big>\\n<tt><small>{calendar}</small></tt>"
            },
            "network": {
                "interface": "wlp*",
                "format-wifi": "📶 {signalStrength}%",
                "format-ethernet": "🌐 {ifname}",
                "format-disconnected": "❌ Disconnected",
                "tooltip-format": "{ifname}: {ipaddr}/{cidr}\\nGateway: {gwaddr}\\nStrength: {signalStrength}%",
                "on-click": "nm-connection-editor"
            },
            "bluetooth": {
                "format": "🔵 {status}",
                "format-connected": "🔵 {device_alias}",
                "format-connected-battery": "🔵 {device_alias} {device_battery_percentage}%",
                "on-click": "~/.config/hypr-system/scripts/bluetooth-control.sh"
            },
            "pulseaudio": {
                "format": "{icon} {volume}%",
                "format-bluetooth": "{icon} {volume}% 🔵",
                "format-bluetooth-muted": "🔇 🔵",
                "format-muted": "🔇",
                "format-icons": {
                    "headphone": "🎧",
                    "hands-free": "🎙️",
                    "headset": "🎧",
                    "phone": "📱",
                    "portable": "📱",
                    "car": "🚗",
                    "default": ["🔈", "🔉", "🔊"]
                },
                "on-click": "pavucontrol",
                "on-click-right": "~/.config/hypr-system/scripts/volume-control.sh mute"
            },
            "battery": {
                "states": {
                    "warning": 30,
                    "critical": 15
                },
                "format": "{icon} {capacity}%",
                "format-charging": "⚡ {capacity}%",
                "format-plugged": "🔌 {capacity}%",
                "format-alt": "{icon} {time}",
                "format-icons": ["🪫", "🔋", "🔋", "🔋", "🔋"]
            },
            "custom/zerotier": {
                "format": "🌐 {}",
                "exec": "~/.config/hypr-system/scripts/zerotier-status.sh",
                "interval": 30,
                "tooltip": True,
                "on-click": "~/.config/hypr-system/scripts/zerotier-control.sh"
            },
            "tray": {
                "spacing": 10
            },
            "custom/config": {
                "format": "⚙️",
                "tooltip": "Configuration Menu",
                "on-click": "~/.config/hypr-system/scripts/config-menu.sh"
            },
            "custom/power": {
                "format": "⚡",
                "tooltip": False,
                "on-click": "~/.config/hypr-system/scripts/power-menu.sh"
            }
        }

        # Write config
        waybar_dir = self.output_dir / "waybar"
        waybar_dir.mkdir(exist_ok=True)
        with open(waybar_dir / "config.jsonc", 'w') as f:
            json.dump(config, f, indent=2)

    def generate_all(self):
        """Generate all configurations"""
        print("🚀 Generating all configurations from templates...")

        # Generate from templates
        configs = [
            ("hyprland", self.output_dir / "hypr" / "hyprland.conf"),
            ("hypr-environment", self.output_dir / "hypr" / "configs" / "environment.conf"),
            ("hypr-animations", self.output_dir / "hypr" / "configs" / "animations.conf"),
            ("hypr-rules", self.output_dir / "hypr" / "configs" / "rules.conf"),
            ("hypr-monitors", self.output_dir / "hypr" / "configs" / "monitors.conf"),
            ("hypr-autostart", self.output_dir / "hypr" / "configs" / "autostart.conf"),
            ("waybar-css", self.output_dir / "waybar" / "style.css"),
            ("rofi-theme", self.output_dir / "rofi" / "themes" / "cyberpunk-medieval.rasi"),
            ("dunst", self.output_dir / "dunst" / "dunstrc"),
            ("kitty", self.output_dir / "kitty" / "kitty.conf"),
        ]

        success_count = 0
        for template_name, output_path in configs:
            if self.generate_from_template(template_name, output_path):
                print(f"✅ Generated {output_path}")
                success_count += 1
            else:
                print(f"❌ Failed to generate {output_path}")

        # Generate keybindings and waybar config (these are special cases)
        self.generate_keybindings()
        self.generate_waybar_config()

        print(f"✅ Generated {success_count}/{len(configs)} configurations successfully!")

        # Reload system
        self.reload_system()

    def reload_system(self):
        """Reload Hyprland and restart services"""
        print("🔄 Reloading system...")

        try:
            # Reload Hyprland
            subprocess.run(["hyprctl", "reload"], check=False, capture_output=True)

            # Restart Waybar
            subprocess.run(["pkill", "waybar"], check=False, capture_output=True)
            subprocess.Popen(["waybar"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            # Restart Dunst
            subprocess.run(["pkill", "dunst"], check=False, capture_output=True)
            subprocess.Popen(["dunst"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            print("✅ System reloaded successfully!")

        except Exception as e:
            print(f"⚠️ Error reloading system: {e}")

def main():
    """Main function"""
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("""
🎨 Master Theme Generator

Usage:
  python apply-theme.py           Generate all configurations
  python apply-theme.py --help    Show this help

This script generates all component configurations from the central
theme-config.json and keybind-config.json files using templates.
""")
        return

    generator = ThemeGenerator()
    generator.generate_all()

if __name__ == "__main__":
    main()
