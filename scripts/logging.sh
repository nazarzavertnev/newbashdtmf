#!/usr/bin/env bash

# Logging functionality with severity levels

# Log an informational message
log_info() {
    echo "[INFO]  [$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Log an error message
log_error() {
    echo "[ERROR] [$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Log a debug message (only if DEBUG=1)
log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] [$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

# Legacy function for backward compatibility
log() {
    log_info "$1"
}
