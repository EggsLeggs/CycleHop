#!/bin/bash
# Update location PNG images with new color scheme:
# - Dark images: black (#000000) -> #1C1C1C
# - Paris highlighted: #2D6A2B -> #00A650
# - New York highlighted: #271A88 -> #00396C

set -e
RESOURCES="$(cd "$(dirname "$0")/.." && pwd)/Resources"
cd "$RESOURCES"

process() {
  local file="$1"
  shift
  if [[ ! -f "$file" ]]; then
    echo "  Skip (not found): $file"
    return
  fi
  local tmp="${file}.tmp.png"
  magick "$file" "$@" "$tmp" && mv "$tmp" "$file"
  echo "  Updated: $(basename "$file")"
}

# NewYorkLocationDark.png: dark only
process "NewYorkLocationDark.png" -fill '#1C1C1C' -opaque '#000000'

# NewYorkLocationDarkHighlighted.png: dark + NY highlight
process "NewYorkLocationDarkHighlighted.png" -fill '#1C1C1C' -opaque '#000000' -fill '#00396C' -opaque '#271A88'

# NewYorkLocationLight.png: no changes
echo "  Skip (no changes): NewYorkLocationLight.png"

# NewYorkLocationLightHighlighted.png: NY highlight only
process "NewYorkLocationLightHighlighted.png" -fill '#00396C' -opaque '#271A88'

# ParisLocationDark.png: dark only
process "ParisLocationDark.png" -fill '#1C1C1C' -opaque '#000000'

# ParisLocationDarkHighlighted.png: dark + Paris highlight
process "ParisLocationDarkHighlighted.png" -fill '#1C1C1C' -opaque '#000000' -fill '#00A650' -opaque '#2D6A2B'

# ParisLocationLight.png: no changes
echo "  Skip (no changes): ParisLocationLight.png"

# ParisLocationLightHighlighted.png: Paris highlight only
process "ParisLocationLightHighlighted.png" -fill '#00A650' -opaque '#2D6A2B'

echo "Done."
