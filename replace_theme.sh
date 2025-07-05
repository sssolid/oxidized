find . -type f -exec sed -i \
  -e 's/accent_primary/accent_primary/g' \
  -e 's/accent_highlight/accent_highlight/g' \
  -e 's/status_success/status_success/g' \
  -e 's/accent_secondary/accent_secondary/g' \
  -e 's/status_info/status_info/g' \
  -e 's/accent_primary/accent_primary/g' \
  -e 's/accent_tertiary/accent_tertiary/g' \
  -e 's/status_error/status_error/g' \
  -e 's/neutral_border_light/neutral_border_light/g' \
  -e 's/neutral_border_dark/neutral_border_dark/g' \
  {} +
