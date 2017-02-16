#!/usr/bin/bash

PACMAN_FLAGS=(
    "--noconfirm"
    "--needed" # does not reistall up-to-date packages
)
TO_BE_UNSET+=( "PACMAN_FLAGS")

adm_pm__pacman() {
    local args=("$@")
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) sudo pacman -S "${PACMAN_FLAGS[@]}" "${packages[@]}" ;;
        remove)  sudo pacman -Rns "${PACMAN_FLAGS[@]}" "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}

hash pacman &>/dev/null && adm_pm_register "pm" "adm_pm__pacman"
