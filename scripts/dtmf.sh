#!/usr/bin/env bash

# DTMF handling

process_dtmf() {
    local digit="$1"
    local mode="$2"
    local current_menu="${menu_stack[-1]}"

    log "detected DTMF: $digit (menu: ${menus[$current_menu]})"

    case $mode in
    'yaschik')
        case "$digit" in
        1)
            echo "HELLO"
            ;;  
        esac
        ;;
    'main')
        case $current_menu in
        0)
            case "$digit" in
            1)
                stop_audio
                radio_stop
                play_audio "$staticf/start_rec.wav"
                record_audio
                menu_stack+=("1")
                ;;
            2)
                menu_stack+=("2")
                ;;
            '*')
                play_audio "$staticf/greet.wav"
                if [ ${#menu_stack[@]} -gt 1 ]; then
                    unset 'menu_stack[-1]'
                fi
                ;;
            esac
            ;;
        1)
            case "$digit" in
            0)
                menu_stack=("0")
                ;;
            '*')
                if [ ${#menu_stack[@]} -gt 1 ]; then
                    unset 'menu_stack[-1]'
                fi
                ;;
            '#')
                stop_record
                play_audio "$staticf/save.wav"
                menu_stack+=("2")
                ;;
            esac
            ;;
        2)
            case "$digit" in
            1)
                trim_loud
                play_audio "$staticf/success.wav"
                radio_pause
                menu_stack=("0")
                ;;
            esac
            ;;
        esac
        ;;
    esac

}
