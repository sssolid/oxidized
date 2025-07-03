#!/usr/bin/env python3
"""
Debug template placeholders to find the source of "Invalid placeholder" errors
"""

import json
import re
from pathlib import Path
from string import Template

def check_template_placeholders():
    """Check all template files for placeholder issues"""
    config_dir = Path.home() / ".config" / "hypr-system"
    template_dir = config_dir / "templates"

    # Load theme config to get available variables
    try:
        with open(config_dir / "core" / "theme-config.json") as f:
            theme_config = json.load(f)
    except:
        print("❌ Could not load theme config")
        return

    if not template_dir.exists():
        print("❌ Templates directory not found")
        return

    # Check each template file
    template_files = [
        "hyprland.template",
        "hypr-animations.template",
        "hypr-rules.template",
        "hypr-environment.template",
        "hypr-monitors.template",
        "hypr-autostart.template",
        "waybar-css.template",
        "rofi-theme.template",
        "dunst.template",
        "kitty.template"
    ]

    print("🔍 Checking template placeholder issues...\n")

    for template_file in template_files:
        template_path = template_dir / template_file
        if not template_path.exists():
            print(f"⚠️  {template_file}: Not found")
            continue

        try:
            with open(template_path, 'r') as f:
                content = f.read()

            print(f"📄 {template_file}:")

            # Find all placeholders
            placeholders = re.findall(r'\$\{([^}]+)\}', content)
            print(f"   Found {len(placeholders)} placeholders")

            # Check for common issues
            issues = []
            lines = content.split('\n')

            for i, line in enumerate(lines, 1):
                # Unclosed placeholders
                if '${' in line and '}' not in line:
                    issues.append(f"Line {i}: Unclosed placeholder")
                    print(f"   ❌ Line {i}: {line.strip()}")

                # Nested braces
                brace_count = line.count('{') - line.count('}')
                if '${' in line and brace_count != 0:
                    issues.append(f"Line {i}: Unbalanced braces")
                    print(f"   ❌ Line {i}: {line.strip()}")

                # Invalid characters in variable names
                invalid_vars = re.findall(r'\$\{([^}]*[-\s\.][^}]*)\}', line)
                if invalid_vars:
                    issues.append(f"Line {i}: Invalid variable names")
                    print(f"   ❌ Line {i}: Invalid vars {invalid_vars}: {line.strip()}")

            # Try template substitution to catch other issues
            try:
                template = Template(content)
                # Test with empty dict to see what variables are needed
                template.substitute({})
            except KeyError as e:
                print(f"   ⚠️  Missing variable: {e}")
            except ValueError as e:
                print(f"   ❌ Template error: {e}")

            if not issues:
                print(f"   ✅ No issues found")

            print()

        except Exception as e:
            print(f"   ❌ Error reading file: {e}\n")

def main():
    print("🗡️ Template Placeholder Debugger\n")
    check_template_placeholders()

    print("💡 Common fixes:")
    print("   - Use ${variable_name} not ${variable-name}")
    print("   - Ensure all { have matching }")
    print("   - Check for typos in variable names")
    print("   - Make sure template variables are defined in get_template_variables()")

if __name__ == "__main__":
    main()
