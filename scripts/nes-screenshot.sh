#!/bin/bash
#
# nes-screenshot - Capture screenshot from NES ROM
#
# Usage:
#   nes-screenshot game.nes output.png [--wait SECONDS]
#
# Options:
#   --wait SECONDS   Wait time before capture (default: 3)
#   --scale N        Scale factor 1-4 (default: 2)
#   --crop           Crop to game viewport only (remove menu bar)
#
# Examples:
#   nes-screenshot game.nes screenshot.png
#   nes-screenshot game.nes screenshot.png --wait 5
#   nes-screenshot game.nes screenshot.png --scale 3 --crop

set -e

# Default values
WAIT_TIME=3
SCALE=2
DISPLAY_NUM=99
CROP=0

# Parse arguments
INPUT_FILE=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --wait)
            WAIT_TIME="$2"
            shift 2
            ;;
        --scale)
            SCALE="$2"
            shift 2
            ;;
        --crop)
            CROP=1
            shift
            ;;
        -h|--help)
            echo "Usage: nes-screenshot INPUT.nes OUTPUT.png [OPTIONS]"
            echo ""
            echo "Capture a screenshot from an NES ROM."
            echo ""
            echo "Arguments:"
            echo "  INPUT   .nes ROM file"
            echo "  OUTPUT  Output PNG file path"
            echo ""
            echo "Options:"
            echo "  --wait SECONDS   Wait before capture (default: 3)"
            echo "  --scale N        Scale factor 1-4 (default: 2)"
            echo "  --crop           Crop to game viewport (remove menu)"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            if [[ -z "$INPUT_FILE" ]]; then
                INPUT_FILE="$1"
            elif [[ -z "$OUTPUT_FILE" ]]; then
                OUTPUT_FILE="$1"
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$INPUT_FILE" ]] || [[ -z "$OUTPUT_FILE" ]]; then
    echo "Error: INPUT and OUTPUT files required"
    echo "Usage: nes-screenshot INPUT.nes OUTPUT.png [--wait SECONDS]"
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

# Verify it's a NES ROM
EXT="${INPUT_FILE##*.}"
EXT="${EXT,,}"  # lowercase

if [[ "$EXT" != "nes" ]]; then
    echo "Error: Expected .nes file, got: $EXT"
    exit 1
fi

# Calculate window size (NES is 256x240, but NTSC typically shows 256x224)
# FCEUX adds UI elements, so we use a larger framebuffer
WIDTH=$((256 * SCALE))
HEIGHT=$((240 * SCALE))

# Start virtual framebuffer - larger than needed to accommodate window decorations
Xvfb :${DISPLAY_NUM} -screen 0 1024x768x24 >/dev/null 2>&1 &
XVFB_PID=$!
sleep 1

# Set display
export DISPLAY=:${DISPLAY_NUM}

# Cleanup function
cleanup() {
    kill $FCEUX_PID 2>/dev/null || true
    kill $XVFB_PID 2>/dev/null || true
}
trap cleanup EXIT

# Run FCEUX with SDL driver
# --xscale and --yscale set the scaling factor
# --nogui disables the GTK GUI (if using GTK version)
# --sound 0 disables sound
timeout $((WAIT_TIME + 10))s /usr/games/fceux \
    --xscale "$SCALE" \
    --yscale "$SCALE" \
    --sound 0 \
    "$INPUT_FILE" >/dev/null 2>&1 &
FCEUX_PID=$!

# Wait for FCEUX to start and create its window
sleep 2

# Wait for program to run
sleep "$WAIT_TIME"

# Find the FCEUX window and capture it
# FCEUX window title is "FCEUX x.x.x" - search case-insensitively
FCEUX_WINDOW=$(xdotool search --name "FCEUX [0-9]" 2>/dev/null | head -1)

if [[ -n "$FCEUX_WINDOW" ]]; then
    # Brief pause to ensure window is fully rendered
    sleep 0.5
    # Capture the FCEUX window content
    import -window "$FCEUX_WINDOW" "$OUTPUT_FILE"
else
    # Fallback: try to capture root window and crop
    echo "Warning: Could not find FCEUX window, capturing root window"
    import -window root "$OUTPUT_FILE"
fi

# Crop to game viewport if requested
# FCEUX has ~22px menu bar at top; viewport is 256*SCALE x 224*SCALE (NTSC)
if [[ "$CROP" -eq 1 ]]; then
    CROP_WIDTH=$((256 * SCALE))
    CROP_HEIGHT=$((224 * SCALE))
    TEMP_FILE="${OUTPUT_FILE%.png}_temp.png"
    mv "$OUTPUT_FILE" "$TEMP_FILE"
    # Crop from top-left after menu bar (approximately 22px menu height)
    convert "$TEMP_FILE" -crop "${CROP_WIDTH}x${CROP_HEIGHT}+0+22" +repage "$OUTPUT_FILE"
    rm "$TEMP_FILE"
fi

# Report actual dimensions
DIMENSIONS=$(identify -format "%wx%h" "$OUTPUT_FILE" 2>/dev/null || echo "unknown")
echo "Screenshot saved: $OUTPUT_FILE ($DIMENSIONS)"
