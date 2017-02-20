#!/usr/bin/bash

TO_BE_UNSET+=( "PIP_FLAGS" )

PIP_FLAGS=( )

adm_pm__pip() {
    local args=( "$@" )
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) pip install "${PIP_FLAGS[@]}" "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}

hash pip &>/dev/null && adm_pm_register "pip" "adm_pm__pip"
