#!/usr/bin/env bash

. "$(dirname "$0")/scripts/config.sh"
. "$(dirname "$0")/scripts/radio.sh"
. "$(dirname "$0")/scripts/dtmf.sh"
. "$(dirname "$0")/scripts/audio.sh"
. "$(dirname "$0")/scripts/logging.sh"

log "Startup ----------"

start_radio &

wait $!

# process_audio_stream 'yaschik'