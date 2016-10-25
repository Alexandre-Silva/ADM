#!/usr/bin/bash

PACMAN_FLAGS=(
    "--noconfirm"
    "--needed" # does not reistall up-to-date packages
)
TO_BE_UNSET+=( "PACMAN_FLAGS")

pm_pacman() {
    local args=("$@")
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) sudo pacman -S "${PACMAN_FLAGS[@]}" "${packages[@]}" ;;
        remove)  sudo pacman -Rns "${PACMAN_FLAGS[@]}" "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}
TO_BE_UNSET_f+=( "pm_pacman" )

[[ -x "/usr/bin/pacman" ]] && pm_register "pm" "pm_pacman"
