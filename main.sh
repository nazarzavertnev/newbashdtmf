#!/usr/bin/env bash

. "$(dirname "$0")/scripts/config.sh"
. "$(dirname "$0")/scripts/logging.sh"
. "$(dirname "$0")/scripts/audio.sh"
. "$(dirname "$0")/scripts/radio.sh"
. "$(dirname "$0")/scripts/dtmf.sh"

log "Startup ----------"

# Start both processes (audio processing and radio) in background and save their PIDs
process_audio_stream 'main' &
audio_pid=$!

start_radio &
radio_pid=$!

# Graceful shutdown function
graceful_shutdown() {
    log "Received termination signal (SIGINT/SIGTERM), stopping child processes..."

    # Properly kill audio process (if alive)
    if ps -p $audio_pid > /dev/null 2>&1; then
        log "Stopping process_audio_stream (PID: $audio_pid)"
        kill -INT $audio_pid
        wait $audio_pid 2>/dev/null
    fi

    # Properly kill radio process (if alive)
    if ps -p $radio_pid > /dev/null 2>&1; then
        log "Stopping radio (PID: $radio_pid)"
        kill -INT $radio_pid
        wait $radio_pid 2>/dev/null
    fi

    log "All child processes stopped. Exiting main.sh"
    exit 0
}

# Set up signal handler: when script receives SIGINT or SIGTERM, call graceful_shutdown
trap graceful_shutdown SIGINT SIGTERM

# Wait for child processes to complete
wait $audio_pid
wait $radio_pid
