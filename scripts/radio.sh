#!/usr/bin/env bash

. "$(dirname "$0")/config.sh"
. "$(dirname "$0")/logging.sh"

# Function to handle pause signal
handle_pause() {
    log_info "Radio received pause signal."
    if [[ -n "$PWPLAY_PID" ]] && kill -0 "$PWPLAY_PID" 2>/dev/null; then
        log_info "Sending SIGSTOP to pw-play PID: $PWPLAY_PID"
        kill -STOP "$PWPLAY_PID" 2>/dev/null
    fi
}

# Function to handle resume signal
handle_resume() {
    log_info "Radio received resume signal."
    if [[ -n "$PWPLAY_PID" ]] && kill -0 "$PWPLAY_PID" 2>/dev/null; then
        log_info "Sending SIGCONT to pw-play PID: $PWPLAY_PID"
        kill -CONT "$PWPLAY_PID" 2>/dev/null
    fi
}

# Function to handle cleanup on exit
radio_cleanup() {
    log_info "Radio shutting down..."
    [[ -n "$PWPLAY_PID" ]] && kill -0 "$PWPLAY_PID" 2>/dev/null && kill -INT "$PWPLAY_PID"
    pkill -P $$ # Kill any other child processes
    log_info "Radio shutdown complete."
    exit 0
}

# Trap signals for pause, resume, and exit
trap handle_pause SIGUSR1
trap handle_resume SIGUSR2
trap radio_cleanup SIGINT SIGTERM EXIT

start_radio() {
    MUSIC_DIR="$radiof"
    PWPLAY_PID="" # PID of the current pw-play process

    log_info "Starting radio playback from $MUSIC_DIR"

    while :; do
        local file
        file=$(find "$MUSIC_DIR" -type f \( -iname '*.mp3' -o -iname '*.wav' -o -iname '*.ogg' -o -iname '*.flac' \) | shuf -n 1)
        if [[ -z "$file" ]]; then
            log_error "No music files found in $MUSIC_DIR. Exiting radio."
            exit 1
        fi

        log_info "Playing radio track: $file"
        # Play intro sound first
        pw-play "$staticf/main.wav" --target="$PLAY_DEV" &
        local intro_pid=$!
        wait "$intro_pid"

        # Check if intro playback was successful before playing the main track
        if [[ $? -eq 0 ]]; then
            pw-play "$file" --target="$PLAY_DEV" &
            PWPLAY_PID=$! # Store the PID of the main track playback
            log_info "Main radio track PID: $PWPLAY_PID"
            wait "$PWPLAY_PID" # Wait for the main track to finish
            PWPLAY_PID="" # Clear PID after track finishes
        else
            log_error "Intro playback failed."
        fi

        # The loop continues to the next track unless a signal causes exit
    done
}

# Control functions to be called from outside
radio_stop() {
    if [[ -n "$radio_pid" ]] && kill -0 "$radio_pid" 2>/dev/null; then
        log_info "Sending SIGINT to radio process $radio_pid"
        kill -INT "$radio_pid" 2>/dev/null
    else
        log_debug "Radio process not running or PID not set."
    fi
}

radio_pause() {
    if [[ -n "$radio_pid" ]] && kill -0 "$radio_pid" 2>/dev/null; then
        log_info "Sending SIGUSR1 to radio process $radio_pid"
        kill -USR1 "$radio_pid" 2>/dev/null
    else
        log_debug "Radio process not running or PID not set."
    fi
}

radio_resume() {
    if [[ -n "$radio_pid" ]] && kill -0 "$radio_pid" 2>/dev/null; then
        log_info "Sending SIGUSR2 to radio process $radio_pid"
        kill -USR2 "$radio_pid" 2>/dev/null
    else
        log_debug "Radio process not running or PID not set."
    fi
}
