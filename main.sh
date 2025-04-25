#!/usr/bin/env bash

. "$(dirname "$0")/scripts/config.sh"
. "$(dirname "$0")/scripts/logging.sh"
. "$(dirname "$0")/scripts/radio.sh" # Подключаем скрипт радио
. "$(dirname "$0")/scripts/audio.sh"
. "$(dirname "$0")/scripts/dtmf.sh"

log "Startup ----------"

# Функция для завершения фоновых процессов
cleanup() {
    log "Shutting down..."
    # Используем функцию radio_stop для отправки сигнала процессу радио
    radio_stop
    # Отправляем сигнал завершения процессу обработки аудио
    if [[ -n "$audio_pid" ]] && kill -0 "$audio_pid" 2>/dev/null; then
        log_info "Sending SIGTERM to audio process $audio_pid"
        kill -TERM "$audio_pid" 2>/dev/null
    fi

    # Ожидание завершения обоих процессов
    wait "$audio_pid" "$radio_pid" 2>/dev/null
    log "Shutdown complete."
    exit 0
}

# Установка обработчика сигналов INT (Ctrl+C) и TERM
trap cleanup INT TERM

process_audio_stream 'main' &
audio_pid=$!
log_info "Audio processing started with PID: $audio_pid"

start_radio &
radio_pid=$! # PID процесса радио сохраняется здесь
log_info "Radio playback started with PID: $radio_pid"


# Ожидание завершения фоновых процессов
wait "$audio_pid" "$radio_pid"

log "Script finished."
