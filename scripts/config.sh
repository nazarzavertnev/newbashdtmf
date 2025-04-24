#!/usr/bin/env bash

# Configuration constants and global variables

PLAY_DEV="bluez_output.14_49_D4_01_82_48.1"
# REC_DEV="bluez_input.14_49_D4_01_82_48.0"
REC_DEV="Firefox"
SAMPLE_RATE="22050"
LOG_FILE="call_center.log"

radiof="audio/radio"
staticf="audio/static"
tmpf="audio/tmp"
notes="audio/notes"

declare -A menus
menus=(
    ["0"]="main"
    ["1"]="rec"
    ["2"]="save"
    ["3"]="tele"
)
menu_stack=("0")

PLAY_PIDS=()
REC_PID=None
REC_NAME=''