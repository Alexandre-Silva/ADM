#!/usr/bin/env bash

PACAUR_FLAGS=( --silent --noedit --noconfirm --noprogressbar --needed )
TO_BE_UNSET+=( "PACAUR_FLAGS")

adm_pm__pacaur() {
    local args=( "$@" )
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) pacaur "${PACAUR_FLAGS[@]}" --sync "${packages[@]}" ;;
        remove)  sudo pacman -Rns "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}

hash pacaur &>/dev/null && adm_pm_register "aur" "adm_pm__pacaur"
