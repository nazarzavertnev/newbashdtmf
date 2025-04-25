#!/usr/bin/env bash

process_audio_stream() {
    pw-record -a --target="$REC_DEV" --rate="$SAMPLE_RATE" --channels=1 - | \
    multimon-ng -t raw -a DTMF - 2>> "$LOG_FILE" | \
    grep --line-buffered "DTMF:" | \
    while read -r line; do
        digit=$(echo "$line" | awk '{print $2}')
        process_dtmf "$digit" "$1"
    done
}

play_audio() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "File not found for playback: $file"
        return 1
    fi
    pw-play "$file" --target="$PLAY_DEV" --volume=1.0 2>> "$LOG_FILE" &
    if [[ $? -ne 0 ]]; then
        log_error "Error starting pw-play for file: $file"
        return 1
    fi
    PLAY_PIDS+=($!)
    log_info "Playing: $file (PID: ${PLAY_PIDS[-1]})"
}

stop_audio() {
    for pid in "${PLAY_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -INT "$pid" 2>/dev/null
            log_info "Stopped playback process with PID: $pid"
        fi
    done
    PLAY_PIDS=()
}

record_audio() {
    local file="$1"  # This parameter is not currently used but reserved for future naming if desired
    REC_NAME="$(date '+%Y%m%d-%H%M%S').ogg"
    pw-record "$tmpf/$REC_NAME" --target="$REC_DEV" --rate="8000" --channels=1 2>> "$LOG_FILE" &
    REC_PID=$!
    if [[ $? -ne 0 ]]; then
        log_error "Error starting pw-record"
        return 1
    fi
    log_info "Recording started: $tmpf/$REC_NAME (PID: $REC_PID)"
}

stop_record() {
    if kill -0 "$REC_PID" 2>/dev/null; then
        kill -INT "$REC_PID" 2>/dev/null
        log_info "Recording stopped (PID: $REC_PID)"
    fi
}

trim_loud() {
    duration=$(ffprobe -i "$tmpf/$REC_NAME" -show_entries format=duration -v quiet -of csv="p=0")
    log_debug "Input file duration: $duration seconds"
    if (( $(echo "$duration > 1" | bc -l) )); then
        ffmpeg -i "$tmpf/$REC_NAME" -filter_complex \
        "[0:a]atrim=start=0.5:duration=$(echo "$duration - 1" | bc),asetpts=PTS-STARTPTS[aud];[aud]loudnorm=I=-5:TP=0:LRA=40" \
        "$notes/$REC_NAME"
        if [[ $? -ne 0 ]]; then
            log_error "Error trimming and normalizing file: $tmpf/$REC_NAME"
        else
            log_info "File recorded, trimmed and normalized: $notes/$REC_NAME"
        fi
    else
        log_error "Input file is too short for trimming: duration $duration"
    fi
    rm "$tmpf/$REC_NAME"
    REC_NAME=''
}