#!/usr/bin/env python3
"""
download_tiles.py — Download OSM raster tiles for BikeHop offline map support.

Usage:
    python3 Scripts/download_tiles.py [--zoom15]

Tiles are saved to:
    Resources/tile_{z}_{x}_{y}.png   (flat naming, no subdirectories)

Flat naming is required because Swift Package Manager's .process("Resources")
copies all PNG files to the bundle root, dropping subdirectory paths. Storing
tiles as tile_{z}_{x}_{y}.png guarantees every filename is globally unique.

If you have an existing Resources/tiles/ directory from a previous run,
delete it before re-running: rm -rf Resources/tiles/

Respects the OpenStreetMap tile usage policy:
  - Identifies itself with a proper User-Agent
  - Limits request rate via a short sleep between downloads
  - Covers only small, bike-share-area bounding boxes

Run this script once from the project root before building the app.
"""

import math
import os
import time
import sys
import urllib.request

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Bounding boxes: (min_lat, max_lat, min_lon, max_lon)
# Each box is 2× the original radius so coverage extends further from city centre.
CITIES = {
    "london":   (51.435, 51.575, -0.225, -0.005),
    "paris":    (48.800, 48.920,  2.225,  2.485),
    "new_york": (40.660, 40.820, -74.060, -73.900),
}

ZOOM_LEVELS = [12, 13, 14]
if "--zoom15" in sys.argv:
    ZOOM_LEVELS.append(15)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "Resources")
TILE_URL   = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
USER_AGENT = "BikeHopApp/1.0 (Apple Student Challenge; github.com/EggsLeggs/CycleHop)"

# Seconds between requests — keep OSM tile servers happy
REQUEST_DELAY = 0.25

# ---------------------------------------------------------------------------
# Slippy-map tile maths (Web Mercator / EPSG:3857)
# ---------------------------------------------------------------------------

def lat_lon_to_tile(lat_deg: float, lon_deg: float, zoom: int) -> tuple[int, int]:
    """Convert WGS-84 lat/lon to OSM tile (x, y) at the given zoom level."""
    lat_r = math.radians(lat_deg)
    n = 2 ** zoom
    x = int((lon_deg + 180.0) / 360.0 * n)
    y = int((1.0 - math.log(math.tan(lat_r) + 1.0 / math.cos(lat_r)) / math.pi) / 2.0 * n)
    return x, y


def tile_range(min_lat, max_lat, min_lon, max_lon, zoom):
    """Return the rectangular range of tile (x, y) indices covering the bbox."""
    x_min, y_max = lat_lon_to_tile(min_lat, min_lon, zoom)  # y increases southward
    x_max, y_min = lat_lon_to_tile(max_lat, max_lon, zoom)
    return range(x_min, x_max + 1), range(y_min, y_max + 1)

# ---------------------------------------------------------------------------
# Download
# ---------------------------------------------------------------------------

def download_tile(z: int, x: int, y: int) -> bool:
    """Download a single tile. Returns True on success, False on failure."""
    # Flat naming: tile_{z}_{x}_{y}.png directly in Resources/
    dest_file = os.path.join(OUTPUT_DIR, f"tile_{z}_{x}_{y}.png")

    if os.path.exists(dest_file):
        return True  # already have it

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    url = TILE_URL.format(z=z, x=x, y=y)
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = resp.read()
        with open(dest_file, "wb") as f:
            f.write(data)
        return True
    except Exception as exc:
        print(f"  WARN: failed to download z={z} x={x} y={y}: {exc}")
        return False


def main():
    total_tiles = 0
    failed = 0

    print("BikeHop tile downloader")
    print(f"Zoom levels: {ZOOM_LEVELS}")
    print(f"Output:      {os.path.abspath(OUTPUT_DIR)}")
    print()

    for city, (min_lat, max_lat, min_lon, max_lon) in CITIES.items():
        print(f"--- {city.upper()} ---")
        for z in ZOOM_LEVELS:
            xs, ys = tile_range(min_lat, max_lat, min_lon, max_lon, z)
            count = len(xs) * len(ys)
            print(f"  z={z}: {len(xs)} × {len(ys)} = {count} tiles", flush=True)
            for x in xs:
                for y in ys:
                    ok = download_tile(z, x, y)
                    total_tiles += 1
                    if not ok:
                        failed += 1
                    time.sleep(REQUEST_DELAY)
        print()

    # Summary — count only files matching tile_{z}_{x}_{y}.png pattern
    tile_files = [
        f for f in os.listdir(OUTPUT_DIR)
        if f.startswith("tile_") and f.endswith(".png")
    ]
    total_bytes = sum(
        os.path.getsize(os.path.join(OUTPUT_DIR, f)) for f in tile_files
    )
    size_mb = total_bytes / 1_048_576

    print(f"Done. {total_tiles} tiles attempted, {failed} failures.")
    print(f"Tile files in Resources/: {len(tile_files)} files, {size_mb:.1f} MB (uncompressed)")
    if size_mb > 20:
        print("WARNING: directory size > 20 MB — consider reducing zoom levels or bounding boxes.")


if __name__ == "__main__":
    main()
