#!/usr/bin/bash

PACAUR_FLAGS=( --silent --noedit --noconfirm --noprogressbar --needed )
TO_BE_UNSET+=( "PACAUR_FLAGS")

pm_pacaur() {
    local args=( "$@" )
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) pacaur "${PACAUR_FLAGS[@]}" --sync "${packages[@]}" ;;
        remove)  sudo pacman -Rns "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}
TO_BE_UNSET_f+=( "pm_pacaur" )

[[ -x "/usr/bin/pacaur" ]] && pm_register "aur" "pm_pacaur"
