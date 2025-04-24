#!/usr/bin/env bash

# Простой скрипт: проиграть случайный аудиофайл через pw-play

# Папка с музыкой (можно поменять на любую)
start_radio(){
    MUSIC_DIR=$radiof
    PWPLAY_PID=""

    cleanup() {
        if [[ -n "$PWPLAY_PID" ]] && kill -0 "$PWPLAY_PID" 2>/dev/null; then
            kill -INT "$PWPLAY_PID"
        fi
        pkill -P $$
        exit 0
    }

    trap cleanup SIGINT SIGTERM EXIT

    while true; do
        local file=$(find "$MUSIC_DIR" -type f \( -iname '*.mp3' -o -iname '*.wav' -o -iname '*.ogg' -o -iname '*.flac' \) | shuf -n 1)
        if [[ -z "$file" ]]; then
            exit 1
        fi

        pw-play "$staticf/main.wav" --target=$PLAY_DEV &
        PWPLAY_PID=$!
        wait $PWPLAY_PID

        pw-play "$radiof/chaos/chaos1.wav" --target=$PLAY_DEV &
        PWPLAY_PID=$!
        wait $PWPLAY_PID

        # pw-play "$file" --target=$PLAY_DEV &
        # PWPLAY_PID=$!
        # wait $PWPLAY_PID
    done
}
