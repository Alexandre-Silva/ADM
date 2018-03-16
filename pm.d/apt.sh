#!/usr/bin/env bash

APT_FLAGS=()
TO_BE_UNSET+=( "APT_FLAGS" )

adm_pm__apt() {
    local args=("$@")
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) sudo apt "${APT_FLAGS[@]}" install "${packages[@]}" ;;
        remove)  sudo apt "${APT_FLAGS[@]}" remove  "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}

if apt &>/dev/null; then
    adm_pm_register "apt" "adm_pm__apt"
fi
