#!/bin/bash
#
# nes-video - Capture video from NES ROM with input injection
#
# Usage:
#   nes-video game.nes output.mp4 [OPTIONS]
#
# Options:
#   --wait SECONDS     Wait time before recording (default: 3)
#   --duration SECONDS Recording duration (default: 10)
#   --fps N            Frame rate (default: 60 for NTSC)
#   --scale N          Scale factor 1-4 (default: 2)
#   --input SCRIPT     Input script to run after wait
#
# Input Scripts:
#   Input scripts are shell scripts that run in the same X display.
#   Use xdotool to send input:
#
#     #!/bin/bash
#     xdotool key Return          # Press key
#     sleep 0.5
#     xdotool key Up Up Up        # Multiple presses
#
#   NES controller mapping (FCEUX defaults):
#     Arrow keys = D-pad
#     Z = A button
#     X = B button
#     Return = Start
#     Shift = Select
#
# Examples:
#   nes-video game.nes gameplay.mp4
#   nes-video game.nes demo.mp4 --wait 2 --duration 30
#   nes-video game.nes demo.mp4 --input scripts/inputs/gameplay-demo.sh

set -e

# Default values
WAIT_TIME=3
DURATION=10
FPS=60
SCALE=2
DISPLAY_NUM=99
INPUT_SCRIPT=""

# Parse arguments
INPUT_FILE=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --wait)
            WAIT_TIME="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --fps)
            FPS="$2"
            shift 2
            ;;
        --scale)
            SCALE="$2"
            shift 2
            ;;
        --input)
            INPUT_SCRIPT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: nes-video INPUT OUTPUT [OPTIONS]"
            echo ""
            echo "Capture video from an NES ROM with input injection."
            echo ""
            echo "Arguments:"
            echo "  INPUT   .nes ROM file"
            echo "  OUTPUT  Output video file (mp4, webm, gif)"
            echo ""
            echo "Options:"
            echo "  --wait SECONDS     Wait before recording (default: 3)"
            echo "  --duration SECONDS Recording length (default: 10)"
            echo "  --fps N            Frame rate (default: 60)"
            echo "  --scale N          Scale factor 1-4 (default: 2)"
            echo "  --input SCRIPT     Input script for key injection"
            echo "  -h, --help         Show this help"
            echo ""
            echo "Controller: Arrow keys, Z=A, X=B, Return=Start, Shift=Select"
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
    echo "Usage: nes-video INPUT OUTPUT [OPTIONS]"
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

if [[ -n "$INPUT_SCRIPT" ]] && [[ ! -f "$INPUT_SCRIPT" ]]; then
    echo "Error: Input script not found: $INPUT_SCRIPT"
    exit 1
fi

# Verify it's a NES ROM
EXT="${INPUT_FILE##*.}"
EXT="${EXT,,}"  # lowercase

if [[ "$EXT" != "nes" ]]; then
    echo "Error: Expected .nes file, got: $EXT"
    exit 1
fi

# Determine output format from extension
OUT_EXT="${OUTPUT_FILE##*.}"
OUT_EXT="${OUT_EXT,,}"

case "$OUT_EXT" in
    mp4)
        # crop=trunc(iw/2)*2:trunc(ih/2)*2 ensures even dimensions for h264
        FFMPEG_CODEC="-vf crop=trunc(iw/2)*2:trunc(ih/2)*2 -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p"
        ;;
    webm)
        FFMPEG_CODEC="-vf crop=trunc(iw/2)*2:trunc(ih/2)*2 -c:v libvpx-vp9 -crf 30 -b:v 0"
        ;;
    gif)
        FFMPEG_CODEC="-vf fps=30,scale=256:-2:flags=lanczos"
        ;;
    *)
        echo "Warning: Unknown output format '$OUT_EXT', using mp4 settings"
        FFMPEG_CODEC="-vf crop=trunc(iw/2)*2:trunc(ih/2)*2 -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p"
        ;;
esac

# Calculate window size (NES: 256x240)
WIDTH=$((256 * SCALE))
HEIGHT=$((240 * SCALE))

# Start virtual framebuffer - needs to be large enough for window placement
SCREEN_W=1024
SCREEN_H=768
Xvfb :${DISPLAY_NUM} -screen 0 ${SCREEN_W}x${SCREEN_H}x24 >/dev/null 2>&1 &
XVFB_PID=$!
sleep 1

# Set display
export DISPLAY=:${DISPLAY_NUM}

# Start window manager (required for xdotool input injection)
openbox >/dev/null 2>&1 &
OPENBOX_PID=$!
sleep 0.5

# Cleanup function
cleanup() {
    kill $FCEUX_PID 2>/dev/null || true
    kill $OPENBOX_PID 2>/dev/null || true
    kill $XVFB_PID 2>/dev/null || true
}
trap cleanup EXIT

# Total runtime needed
TOTAL_TIME=$((WAIT_TIME + DURATION + 10))

# Run FCEUX
echo "Starting FCEUX emulator..."
timeout ${TOTAL_TIME}s /usr/games/fceux \
    --xscale "$SCALE" \
    --yscale "$SCALE" \
    --sound 0 \
    "$INPUT_FILE" >/dev/null 2>&1 &
FCEUX_PID=$!

# Wait for FCEUX to start and create window
sleep 2

# Find FCEUX window
FCEUX_WINDOW=""
for i in {1..20}; do
    FCEUX_WINDOW=$(xdotool search --name "FCEUX" 2>/dev/null | head -1)
    if [[ -n "$FCEUX_WINDOW" ]]; then
        echo "Found FCEUX window: $FCEUX_WINDOW"
        break
    fi
    sleep 0.5
done

if [[ -z "$FCEUX_WINDOW" ]]; then
    echo "Warning: Could not find FCEUX window, input injection may not work"
fi

# Wait for NES to boot and program to start
echo "Waiting ${WAIT_TIME}s for boot..."
sleep "$WAIT_TIME"

# Run input script if provided
if [[ -n "$INPUT_SCRIPT" ]]; then
    echo "Running input script: $INPUT_SCRIPT"
    # Export window ID for scripts that want it
    export FCEUX_WINDOW
    bash "$INPUT_SCRIPT"
    sleep 0.5
fi

echo "Recording ${DURATION}s of video..."

# Get window geometry for precise capture
GRAB_X=0
GRAB_Y=0
GRAB_W=$WIDTH
GRAB_H=$HEIGHT

if [[ -n "$FCEUX_WINDOW" ]]; then
    # Get actual window geometry
    GEOM=$(xdotool getwindowgeometry "$FCEUX_WINDOW" 2>/dev/null)
    if [[ -n "$GEOM" ]]; then
        # Parse "  Position: X,Y (screen: 0)" and "  Geometry: WxH"
        GRAB_X=$(echo "$GEOM" | grep Position | sed 's/.*Position: \([0-9]*\),.*/\1/')
        GRAB_Y=$(echo "$GEOM" | grep Position | sed 's/.*Position: [0-9]*,\([0-9]*\).*/\1/')
        GEOM_SIZE=$(echo "$GEOM" | grep Geometry | sed 's/.*Geometry: \([0-9]*\)x\([0-9]*\).*/\1x\2/')
        GRAB_W=$(echo "$GEOM_SIZE" | cut -dx -f1)
        GRAB_H=$(echo "$GEOM_SIZE" | cut -dx -f2)
        echo "Window geometry: ${GRAB_W}x${GRAB_H} at ${GRAB_X},${GRAB_Y}"

        # Sanity check - if geometry seems wrong, use defaults
        if [[ "$GRAB_W" -lt 100 ]] || [[ "$GRAB_H" -lt 100 ]]; then
            echo "Warning: Invalid geometry detected, using full screen capture"
            GRAB_X=0
            GRAB_Y=0
            GRAB_W=$SCREEN_W
            GRAB_H=$SCREEN_H
        fi
    fi
fi

# Capture video
ffmpeg -y \
    -f x11grab \
    -framerate "$FPS" \
    -video_size "${GRAB_W}x${GRAB_H}" \
    -i ":${DISPLAY_NUM}+${GRAB_X},${GRAB_Y}" \
    -t "$DURATION" \
    $FFMPEG_CODEC \
    "$OUTPUT_FILE" \
    2>/dev/null

# Report result
if [[ -f "$OUTPUT_FILE" ]]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "Video saved: $OUTPUT_FILE ($SIZE)"
else
    echo "Error: Failed to create video"
    exit 1
fi
