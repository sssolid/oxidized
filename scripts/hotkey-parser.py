#!/usr/bin/env python3
"""
⌨️ Dynamic Hotkey Parser
Parses keybind-config.json and generates dynamic hotkey displays
"""

import json
import sys
import argparse
from pathlib import Path

class HotkeyParser:
    def __init__(self):
        self.config_dir = Path.home() / ".config" / "hypr-system"
        self.keybind_config = self.load_keybind_config()

    def load_keybind_config(self):
        """Load keybinding configuration"""
        try:
            with open(self.config_dir / "core" / "keybind-config.json") as f:
                return json.load(f)
        except FileNotFoundError:
            print("❌ Keybind config not found. Please ensure keybind-config.json exists.")
            return {"categories": {}}

    def format_key_combo(self, key_combo):
        """Format key combination for display"""
        # Replace common key names with symbols
        replacements = {
            'SUPER': '⊞',
            'SHIFT': '⇧',
            'CTRL': '⌃',
            'ALT': '⌥',
            'RETURN': '↵',
            'SPACE': '␣',
            'left': '←',
            'right': '→',
            'up': '↑',
            'down': '↓',
            'XF86AudioRaiseVolume': '🔊+',
            'XF86AudioLowerVolume': '🔉-',
            'XF86AudioMute': '🔇',
            'XF86AudioPlay': '⏯️',
            'XF86AudioNext': '⏭️',
            'XF86AudioPrev': '⏮️',
            'XF86MonBrightnessUp': '☀️+',
            'XF86MonBrightnessDown': '☀️-',
            'Print': '📷'
        }

        formatted = key_combo
        for old, new in replacements.items():
            formatted = formatted.replace(old, new)

        return formatted

    def parse_for_json(self):
        """Parse hotkeys for JSON output (EWW consumption)"""
        categories = []

        for cat_id, category in self.keybind_config['categories'].items():
            cat_data = {
                "id": cat_id,
                "name": category['name'],
                "icon": category['icon'],
                "bindings": []
            }

            for key_combo, binding in category['bindings'].items():
                cat_data['bindings'].append({
                    "key": self.format_key_combo(key_combo),
                    "key_raw": key_combo,
                    "description": binding['description'],
                    "command": binding['command']
                })

            categories.append(cat_data)

        return {"categories": categories}

    def parse_for_text(self):
        """Parse hotkeys for text output (rofi fallback)"""
        lines = []

        for category in self.keybind_config['categories'].values():
            lines.append(f"\n{category['name']}")
            lines.append("=" * len(category['name']))

            for key_combo, binding in category['bindings'].items():
                formatted_key = self.format_key_combo(key_combo)
                lines.append(f"{formatted_key:<25} {binding['description']}")

        return "\n".join(lines)

    def parse_for_rofi(self):
        """Parse hotkeys for rofi dmenu format"""
        lines = []

        for category in self.keybind_config['categories'].values():
            for key_combo, binding in category['bindings'].items():
                formatted_key = self.format_key_combo(key_combo)
                lines.append(f"{formatted_key} → {binding['description']}")

        return "\n".join(lines)

    def search_hotkeys(self, query):
        """Search hotkeys by description or key combination"""
        results = []
        query_lower = query.lower()

        for category in self.keybind_config['categories'].values():
            for key_combo, binding in category['bindings'].items():
                if (query_lower in binding['description'].lower() or
                    query_lower in key_combo.lower()):

                    formatted_key = self.format_key_combo(key_combo)
                    results.append({
                        "key": formatted_key,
                        "description": binding['description'],
                        "command": binding['command'],
                        "category": category['name']
                    })

        return results

    def get_category_count(self):
        """Get count of categories and total bindings"""
        total_bindings = sum(len(cat['bindings'])
                           for cat in self.keybind_config['categories'].values())

        return {
            "categories": len(self.keybind_config['categories']),
            "total_bindings": total_bindings
        }

def main():
    parser = argparse.ArgumentParser(description='Dynamic Hotkey Parser')
    parser.add_argument('--json', action='store_true',
                       help='Output in JSON format for EWW')
    parser.add_argument('--rofi', action='store_true',
                       help='Output in rofi dmenu format')
    parser.add_argument('--search', type=str,
                       help='Search hotkeys by description or key')
    parser.add_argument('--count', action='store_true',
                       help='Show count of categories and bindings')

    args = parser.parse_args()

    hotkey_parser = HotkeyParser()

    try:
        if args.json:
            result = hotkey_parser.parse_for_json()
            print(json.dumps(result, indent=2))
        elif args.rofi:
            result = hotkey_parser.parse_for_rofi()
            print(result)
        elif args.search:
            results = hotkey_parser.search_hotkeys(args.search)
            if results:
                for result in results:
                    print(f"{result['key']} → {result['description']} ({result['category']})")
            else:
                print("No matching hotkeys found.")
        elif args.count:
            count = hotkey_parser.get_category_count()
            print(f"Categories: {count['categories']}, Total bindings: {count['total_bindings']}")
        else:
            # Default text output
            result = hotkey_parser.parse_for_text()
            print(result)

    except Exception as e:
        print(f"Error parsing hotkeys: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
