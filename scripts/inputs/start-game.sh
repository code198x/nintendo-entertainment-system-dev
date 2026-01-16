#!/bin/bash
#
# start-game.sh - Press Start to begin game
#
# NES controller mapping (FCEUX defaults):
#   Arrow keys = D-pad
#   Z = A button
#   X = B button
#   Return = Start
#   Shift = Select
#
# Environment: FCEUX_WINDOW is set by nes-video.sh
#

# Focus the FCEUX window first
xdotool windowactivate --sync "$FCEUX_WINDOW"
sleep 0.3

# Press Start to begin
xdotool key Return
sleep 0.5
