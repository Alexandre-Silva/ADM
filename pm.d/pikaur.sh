#!/usr/bin/env bash

PIKAUR_FLAGS=( --noedit --noconfirm --noprogressbar --needed )
TO_BE_UNSET+=( "PIKAUR_FLAGS" )

adm_pm__pikaur() {
    local args=( "$@" )
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) pikaur "${PIKAUR_FLAGS[@]}" --sync "${packages[@]}" ;;
        remove)  sudo pacman -Rns "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}

if hash pikaur &>/dev/null; then
    adm_pm_register "aur" "adm_pm__pikaur"
fi
