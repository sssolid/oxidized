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

        # MISSING CODE: Process semantic colors and resolve their references
        if 'semantic' in theme['colors']:
            for name, color_ref in theme['colors']['semantic'].items():
                resolved_color = self.resolve_color(color_ref)
                vars_dict[name] = resolved_color

        # Add theme settings
        vars_dict.update({
            'font_primary': theme.get('typography', {}).get('font_primary', 'JetBrains Mono Nerd Font'),
            'font_secondary': theme['typography']['font_secondary'],
            'font_size_small': theme['typography']['size_small'],
            'font_size_normal': theme['typography']['size_normal'],
            'font_size_large': theme['typography']['size_large'],
            'font_size_title': theme['typography']['size_title'],

            'primary_bg_overlay': theme['colors']['primary'].get('bg_overlay', theme['colors']['primary']['bg_secondary']),

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

    def get_workspace_variables(self):
        """Get workspace-specific template variables"""
        workspace_config = self.theme_config.get('workspaces', {})
        mode = workspace_config.get('mode', 'virtual_desktops')

        # Generate plugin configuration
        plugin_config = ""
        if mode == 'virtual_desktops':
            vdesk_config = workspace_config.get('virtual_desktops', {}).get('plugin_config', {})
            if vdesk_config:
                plugin_config = "plugin {\n  virtual-desktops {\n"
                for key, value in vdesk_config.items():
                    plugin_config += f"    {key} = {value}\n"
                plugin_config += "  }\n}\n"

        # Generate keybindings
        keybindings = ""
        if mode == 'virtual_desktops':
            keybindings += "# Virtual desktop keybindings\n"
            keybindings += "bind = SUPER, bracketleft, backcyclevdesks\n"
            keybindings += "bind = SUPER, bracketright, cyclevdesks\n"
            keybindings += "bind = SUPER, 1, vdesk, 1\n"
            keybindings += "bind = SUPER, 2, vdesk, 2\n"
            keybindings += "bind = SUPER, 3, vdesk, 3\n"
            keybindings += "bind = SUPER SHIFT, 1, movetodesksilent, 1\n"
            keybindings += "bind = SUPER SHIFT, 2, movetodesksilent, 2\n"
            keybindings += "bind = SUPER SHIFT, 3, movetodesksilent, 3\n"
        else:
            keybindings += "# Per-monitor workspace keybindings\n"
            for i in range(1, 11):
                keybindings += f"bind = SUPER, {i}, workspace, {i}\n"
            for i in range(1, 11):
                keybindings += f"bind = SUPER SHIFT, {i}, movetoworkspace, {i}\n"
            keybindings += "bind = SUPER, bracketright, workspace, m+1\n"
            keybindings += "bind = SUPER, bracketleft, workspace, m-1\n"

        # Generate monitor assignments (for per-monitor mode)
        monitor_assignments = ""
        if mode == 'per_monitor':
            try:
                import subprocess
                result = subprocess.run(['hyprctl', 'monitors', '-j'],
                                        capture_output=True, text=True)
                if result.returncode == 0:
                    monitors_data = json.loads(result.stdout)
                    if len(monitors_data) >= 2:
                        monitor_assignments += "# Monitor workspace assignments\n"
                        # Primary monitor: workspaces 1-5
                        for i in range(1, 6):
                            monitor_assignments += f"workspace = {i}, monitor:{monitors_data[0]['name']}\n"
                        # Secondary monitor: workspaces 6-10
                        for i in range(6, 11):
                            monitor_assignments += f"workspace = {i}, monitor:{monitors_data[1]['name']}\n"
            except:
                pass

        return {
            'workspace_plugin_config': plugin_config,
            'workspace_keybindings': keybindings,
            'monitor_assignments': monitor_assignments
        }

    def generate_workspaces(self):
        """Generate workspace configuration"""
        print("🗡️ Generating workspace configuration...")

        workspace_vars = self.get_workspace_variables()

        success = self.generate_from_template(
            'hypr-workspaces',
            self.output_dir / "hypr" / "configs" / "workspaces.conf",
            workspace_vars
        )

        if success:
            print("✅ Workspace configuration generated")
        else:
            print("❌ Failed to generate workspace configuration")

    def switch_workspace_mode(self):
        """Switch between virtual_desktops and per_monitor modes"""
        current_mode = self.theme_config.get('workspaces', {}).get('mode', 'virtual_desktops')
        new_mode = 'per_monitor' if current_mode == 'virtual_desktops' else 'virtual_desktops'

        # Update theme config
        if 'workspaces' not in self.theme_config:
            self.theme_config['workspaces'] = {}
        self.theme_config['workspaces']['mode'] = new_mode

        # Save updated config
        with open(self.config_dir / "core" / "theme-config.json", 'w') as f:
            json.dump(self.theme_config, f, indent=2)

        print(f"🔄 Switched workspace mode to: {new_mode}")

        # Regenerate workspace config
        self.generate_workspaces()

        # Reload Hyprland
        try:
            subprocess.run(['hyprctl', 'reload'], check=True)
            subprocess.run(['notify-send', '🗡️ Workspace Mode Changed',
                            f'Switched to {new_mode.replace("_", " ").title()}', '-t', '3000'])
        except:
            print("⚠️ Could not reload Hyprland")

        return new_mode

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
        self.generate_workspaces()

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
    generator = ThemeGenerator()

    if len(sys.argv) > 1:
        if sys.argv[1] == "--help":
            print("""
🎨 Master Theme Generator

Usage:
  python apply-theme.py                      Generate all configurations
  python apply-theme.py --switch-workspace-mode    Switch workspace mode
  python apply-theme.py --help              Show this help
""")
            return
        elif sys.argv[1] == "--switch-workspace-mode":
            generator.switch_workspace_mode()
            return

    generator.generate_all()

if __name__ == "__main__":
    main()
